// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

library LootProperties {
    /*
    ```This is a Gemstone.
    It is perfectly round.
    It weighs 1.602 Kg(s).
    It's surface is smooth.
    It is white in color.
    There are pearly stripes across it's surface.
    The air humms around it.
    It is warm to the touch.```
*/

    struct LootData {
        uint8 material;
        uint8 color;
        uint8 weight;
        uint8 rarity; // change to `condition`
    }

    uint256 internal constant MATERIAL = 0 * 0x8;
    uint256 internal constant COLOR = 1 * 0x8;
    uint256 internal constant WEIGHT = 2 * 0x8;
    uint256 internal constant RARITY = 4 * 0x8;

    function getBits8(uint256 value, uint256 from)
        internal
        pure
        returns (uint8)
    {
        return uint8((value & (0xff << from)) >> from);
    }

    function getMaterial(uint256 value) public pure returns (uint8) {
        return getBits8(value, MATERIAL);
    }

    function getColor(uint256 value) public pure returns (uint8) {
        return getBits8(value, COLOR);
    }

    function getWeight(uint256 value) public pure returns (uint8) {
        return getBits8(value, WEIGHT);
    }

    function getRarity(uint256 value) public pure returns (uint8) {
        return getBits8(value, RARITY);
    }

    function getValue(LootData memory props) public pure returns (uint256) {
        return
            combineProperties(
                props.material,
                props.color,
                props.weight,
                props.rarity
            );
    }

    function combineProperties(
        uint8 material,
        uint8 color,
        uint8 weight,
        uint8 rarity
    ) public pure returns (uint256) {
        return
            uint256(
                (uint256(rarity) << RARITY) |
                    (uint256(weight) << WEIGHT) |
                    (uint256(color) << COLOR) |
                    uint256(material)
            );
    }

    function getProperties(uint256 value)
        public
        pure
        returns (LootData memory)
    {
        return LootData({
            material: getMaterial(value),
            color: getColor(value),
            weight: getWeight(value),
            rarity: getRarity(value)
        });

    }

    function createProperties(uint256 seed) public pure returns (uint256) {
        uint256 qualities = seed;
        // needs more shuffling (?)
        return qualities;
    }

    function writeBits8(
        uint256 properties,
        uint8 value,
        uint256 to
    ) public pure returns (uint256) {
        return uint256(properties | uint256(value & (0xff << to)));
    }

    function applyTo(LootData memory props, uint256 value)
        public pure
        returns (uint256)
    {
        uint256 v = writeBits8(value, props.material, MATERIAL);
        v = writeBits8(v, props.color, COLOR);
        v = writeBits8(v, props.weight, WEIGHT);
        v = writeBits8(v, props.rarity, RARITY);
        return v;
    }

    function shuffleProperties(uint256 value, uint256 random)
        public
        pure
        returns (uint256)
    {
        // LootData memory props = getProperties(value);
        // Transform stone into another one

        // props.color = props.color ^ getBits8(random, COLOR);
        uint8 color = getColor(value) ^ getBits8(random, COLOR);
        uint8 material = getMaterial(value) ^ getBits8(random, MATERIAL);
        // props.material = props.material ^ getBits8(random, MATERIAL);
        uint8 weight = getWeight(value) ^ getBits8(random, WEIGHT);
        // rarity should go up on shuffling
        // props.rarity = props.rarity ^ getBits8(random, RARITY);
        uint8 rarity = getRarity(value) ^ getBits8(random, RARITY);

        //
        uint256 v = writeBits8(value, material, MATERIAL);
        v = writeBits8(v, color, COLOR);
        v = writeBits8(v, weight, WEIGHT);
        v = writeBits8(v, rarity, RARITY);

        return v;
    }

    /**
        @dev Generates a seed using keccak256 with a uint256 and an address as inputs.
        @param seed uint256 used as preseed
        @param owner address of the loot's owner
        @return the token's id.
    */
    function makeSeed(uint256 seed, address owner)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(seed, owner)));
    }
}
