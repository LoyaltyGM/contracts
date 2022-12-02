// // Copyright (c) LoyaltyGM.

#[test_only]
module nft_reveal::loot_box_tests {
    use nft_reveal::loot_box;
    use sui::test_scenario::{Self, Scenario};
    // use std::debug;
    use sui::sui::SUI;
    use sui::coin;

     // So these are our heroes.
    const OWNER: address = @0x0;
    const MINTER_1: address = @0x1;
    const MINTER_2: address = @0x2;
    const RANDOM: address = @123;

    const COIN_TO_BUY_BOX: u64 = 10000000; 
    const LESS_COINS_TO_BUY_BOX: u64 = 10;

    fun create_collection(scenario: &mut Scenario){
        // Create lootbox collection 
        test_scenario::next_tx(scenario, OWNER);
        {
            loot_box::create_lootbox(test_scenario::ctx(scenario));
        };
    }

    fun buy_one_lootbox(scenario: &mut Scenario, token_paid: u64) {
        // buy one box 
        test_scenario::next_tx(scenario, MINTER_1);
        {
           // get struct BoxCollection
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           let sui = coin::mint_for_testing<SUI>(token_paid, test_scenario::ctx(scenario));
           loot_box::buy_box(lootbox, sui, test_scenario::ctx(scenario));
           assert!(loot_box::get_box_minted(lootbox) == 1, 1);
           // !!! need to return called structure
           test_scenario::return_shared(lootbox_val);
        };
    }

    fun open_lootbox(scenario: &mut Scenario) {
        // open box
        test_scenario::next_tx(scenario, MINTER_1);
        {
           let box_val = test_scenario::take_from_sender<loot_box::LootBox>(scenario);
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           assert!(loot_box::get_box_minted(lootbox) == 1, 1);

           // open box
           loot_box::open_box(lootbox, box_val, test_scenario::ctx(scenario));
           assert!(loot_box::get_box_opened(lootbox) == 1, 2);
           test_scenario::return_shared(lootbox_val);
        };
    }

    #[test]
    fun normal_workflow() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        create_collection(scenario);
        buy_one_lootbox(scenario, COIN_TO_BUY_BOX);
        open_lootbox(scenario);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun not_enough_money() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;
        create_collection(scenario);
        buy_one_lootbox(scenario, LESS_COINS_TO_BUY_BOX);
        test_scenario::end(scenario_val);
    }

    

}