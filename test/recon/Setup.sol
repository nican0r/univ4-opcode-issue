// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IHooks} from "src/interfaces/IHooks.sol";
import {Hooks} from "src/libraries/Hooks.sol";
import {TickMath} from "src/libraries/TickMath.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {StateLibrary} from "src/libraries/StateLibrary.sol";
import {PoolId, PoolIdLibrary} from "src/types/PoolId.sol";
import {PoolKey} from "src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "src/types/Currency.sol";
import {IPoolManager} from "src/interfaces/IPoolManager.sol";
import {Counter} from "./Counter.sol";

abstract contract Setup is Test, Deployers, BaseSetup {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    Counter hook;
    PoolId poolId;
    PoolKey[] public poolKeys;

    function setup() internal virtual override {
        // creates the pool manager, utility routers, and test tokens
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG |
                    Hooks.AFTER_SWAP_FLAG |
                    Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        deployCodeTo("Counter.sol:Counter", abi.encode(manager), flags);
        hook = Counter(flags);

        // Create the pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(hook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

        // Provide full-range liquidity to the pool
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10_000 ether, 0),
            ZERO_BYTES
        );

        // TODO: remove if no longer needed
        poolKeys.push(key);
        poolKeys.push(nativeKey);
    }
}
