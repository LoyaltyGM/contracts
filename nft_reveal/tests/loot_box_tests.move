// Copyright (c) LoyaltyGM.

#[test_only]
module nft_reveal::loot_box_tests {
    use nft_reveal::loot_box::{Self};
    use sui::test_scenario::{Self};

    #[test]
    fun loot_box() {
         // So these are our heroes.
        let owner = @0x0;
        // let minter1 = @0x1;
        // let minter2 = @0x2;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            loot_box::init_for_testing(test_scenario::ctx(scenario));
        };
        test_scenario::end(scenario_val);
    }
}