// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "./ERC1271.sol";

interface IRLoot {
    function mintLoot(uint256 properties, address to) external returns (uint256);

    function updateLoot(uint256 lootId, uint256 properties)
        external
        returns (bool);

    function destroyLoot(uint256 lootId) external returns (bool);

    function setHolder(
        uint256 tokenId,
        address newHolder,
        bytes calldata permission
    ) external returns (bool);

    function isHolding(address holder, uint256 tokenId)
        external
        view
        returns (bool);
}

contract RLoot is
    IRLoot,
    Ownable,
    IERC721Metadata,
    ERC721Enumerable,
    ERC721Holder,
    EIP712("rLoot", "1.0.0"),
    ERC1271
{
    struct LootHolder {
        address holder;
        uint256 nonce;
    }

    // loots
    uint256[] public loots;
    // map token id => true if the token was destroyed, false otherwise.
    mapping(uint256 => bool) public destroyed;
    // map worker => true if the address is a worker, false otherwise.
    mapping(address => bool) public workers;
    // map token id => token holder data.
    mapping(uint256 => LootHolder) public holders;

    // base uri for metadata url
    string private _uri;

    bytes32 public constant SET_HOLDER_TYPEHASH =
        keccak256(
            "setHolder(address holder,address receiver,uint256 tokenId,uint256 nonce)"
        );

    event UpdateLoot(uint256 indexed lootId, uint256 properties);

    constructor() ERC721("rLOOT", "rLOOT") Ownable() {
        _mintLoot(0, msg.sender, 0);
        _uri = "";
    }

    /// @notice mints a loot
    /// @param properties number representing the properties
    /// @param to address of the owner
    function mintLoot(uint256 properties, address to)
        public
        override
        onlyWorker
        returns (uint256)
    {
        uint256 lootId = loots.length;
        // loots.push(properties);
        // holders[lootId] = LootHolder({holder: to, nonce: 0});
        // destroyed[lootId] = false;
        // super._mint(to, lootId);
        _mintLoot(properties, to, lootId);
        emit UpdateLoot(lootId, properties);
    }

    function _mintLoot(uint256 properties, address to, uint256 lootId)
        internal
        returns (uint256)
    {
        loots.push(properties);
        holders[lootId] = LootHolder({holder: to, nonce: 0});
        destroyed[lootId] = false;

        super._mint(to, lootId);
        return lootId;
    }


    /// @notice updates a loot
    /// @param lootId tokenId of the loot to update
    /// @param properties number representing the properties
    function updateLoot(uint256 lootId, uint256 properties)
        public
        override
        onlyWorker
        returns (bool)
    {
        require(lootId < loots.length, "destroyLoot: invalid loot id");

        // is worker holding the token?
        require(isHolding(msg.sender, lootId), "not holding");

        // update loot's properties
        loots[lootId] = properties;
        // emit event
        emit UpdateLoot(lootId, properties);
        return true;
    }

    /// @notice destroys a loot
    /// @param lootId tokenId of the loot to destroy
    function destroyLoot(uint256 lootId) public override onlyWorker returns (bool)
    {
        require(lootId < loots.length, "destroyLoot: invalid loot id");
        // is worker holding the token?
        require(isHolding(msg.sender, lootId), "not holding");
        destroyed[lootId] = true;
        _burn(lootId);

        return true;
    }


    function setHolder(
        uint256 tokenId,
        address newHolder,
        bytes memory permission
    )
        public
        override
        onlyValidSignature(
            ownerOf(tokenId),
            getPermissionHash(SET_HOLDER_TYPEHASH, newHolder, tokenId),
            permission
        )
        returns (bool)
    {
        // set holder and increase nonce
        LootHolder memory holder = holders[tokenId];
        holders[tokenId] = LootHolder({
            holder: newHolder,
            nonce: holder.nonce + 1
        });

        return true;
    }

    // getters

    function isDestroyed(uint256 tokenId) public view returns (bool) {
        return destroyed[tokenId];
    }

    function getProperties(uint256 tokenId) public view returns (uint256) {
        return loots[tokenId];
    }

    function getHolderData(uint256 tokenId) public view returns (LootHolder memory) {
        return holders[tokenId];
    }

    //
    function isHolding(address holder, uint256 tokenId) public view override returns (bool) {
        return holders[tokenId].holder == holder;
    }


    // workers whitelisting

    // is this really necessary?
    function approveWorker(address worker) public {
        require(workers[worker], "you can only approve authorized workers");
        setApprovalForAll(worker, true);
    }

    function addWorker(address worker) public onlyOwner {
        workers[worker] = true;
    }

    function removeWorker(address worker) public onlyOwner {
        workers[worker] = false;
    }

    modifier onlyWorker() {
        require(workers[msg.sender], "only workers");
        _;
    }

    // NFT metadata

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, IERC721Metadata)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Strings.toString(tokenId)
                )
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        if (from != address(0)) {
            require(isHolding(from, tokenId));
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getPermissionHash(
        bytes32 eip712TypeHash,
        address receiver,
        uint256 tokenId
    ) public view returns (bytes32 permissionHash) {
        LootHolder memory holder = holders[tokenId];
        return
            EIP712._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        eip712TypeHash,
                        holder.holder,
                        receiver,
                        tokenId,
                        holder.nonce
                    )
                )
            );
    }
}
