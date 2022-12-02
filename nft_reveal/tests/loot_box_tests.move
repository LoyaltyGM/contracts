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
    const MINTER1: address = @0x1;
    const MINTER2: address = @0x2;
    const RANDOM: address = @123;

    #[test]
    fun simple_lootbox() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        // Create LootBox 
        test_scenario::next_tx(scenario, OWNER);
        {
            loot_box::create_lootbox(test_scenario::ctx(scenario));
        };

        // buy one box 
        test_scenario::next_tx(scenario, MINTER1);
        {
           // get struct BoxCollection
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           let num_coins: u64 = 10000000;
           let sui = coin::mint_for_testing<SUI>(num_coins, test_scenario::ctx(scenario));
           loot_box::buy_box(lootbox, sui, test_scenario::ctx(scenario));
           assert!(loot_box::get_box_minted(lootbox) == 1, 1);
           // !!! need to return called structure
           test_scenario::return_shared(lootbox_val);
        };

        // open box
        test_scenario::next_tx(scenario, MINTER1);
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

        test_scenario::end(scenario_val);
    }

}