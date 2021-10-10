// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library LootProperties {

    struct LootData {
        uint8 material;
        uint8 color;
        uint8 weight;
        uint8 rarity;
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

    /// @notice combine the given properties into a single value.
    /// @dev this may not work for complex/large entities
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

    /// @notice 
    /// @param value the properties
    /// @return A LootData representing the given `value`
    function getProperties(uint256 value)
        public
        pure
        returns (LootData memory)
    {
        return LootData({
            rarity: getRarity(value),
            color: getColor(value),
            material: getMaterial(value),
            weight: getWeight(value)
        });

    }

    /// @notice creates properties from a given seed number.
    /// @param seed a randomly generated number
    function createProperties(uint256 seed) public pure returns (uint256) {
        uint256 qualities = seed;
        // needs more shuffling (?)
        return qualities;
    }

    /// @notice Overwrite `value` at `position` in `properties`.
    /// @param properties the properties
    /// @param value value to write 
    /// @param position position where the value is written
    function writeBits8(
        uint256 properties,
        uint8 value,
        uint256 position
    ) public pure returns (uint256) {
        return uint256(properties | uint256(value & (0xff << position)));
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

    function shuffleProperties(uint256 properties, uint256 random)
        public
        pure
        returns (uint256)
    {
        // xor each property with 8 random bits
        uint8 color = getColor(properties) ^ getBits8(random, COLOR);
        uint8 material = getMaterial(properties) ^ getBits8(random, MATERIAL);
        uint8 weight = getWeight(properties) ^ getBits8(random, WEIGHT);
        uint8 rarity = getRarity(properties) ^ getBits8(random, RARITY);

        // overwrite each property within `value` with their new value.
        uint256 v = writeBits8(properties, material, MATERIAL);
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
