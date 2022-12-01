// // Copyright (c) LoyaltyGM.

#[test_only]
module nft_reveal::loot_box_tests {
    use nft_reveal::loot_box;
    use sui::test_scenario;
    //use sui::object::{Self};
    use std::debug;
    use sui::sui::SUI;
    use sui::coin;

     // So these are our heroes.
    const OWNER: address = @0x0;
    const MINTER1: address = @0x1;
    const MINTER2: address = @0x2;
    const RANDOM: address = @123;

    #[test]
    fun simple_loot_box_test() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        //let ctx = test_scenario::ctx(scenario);
        // generate unique loot box ID, but we can use it only when create
        // we need to create copy of id
        // let id = object::new(ctx);
        // copy of id
        //let loot_box_id = object::uid_to_inner(&id);

        // Create LootBox 
        test_scenario::next_tx(scenario, OWNER);
        {
            loot_box::create_lootbox(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, MINTER1);
        {
           // Store object BoxCollection
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           debug::print(lootbox);
           assert!(loot_box::owner(lootbox) == OWNER, 0);
           debug::print(&loot_box::owner(lootbox));
           
           let ctx = test_scenario::ctx(scenario);
           let num_coins = 10000000;
           let sui = coin::mint_for_testing<SUI>(num_coins, ctx);

           loot_box::buy_box(lootbox, sui, test_scenario::ctx(scenario));
           assert!(loot_box::get_box_minted(lootbox) == 1, 1);

           test_scenario::return_shared(lootbox_val);
        };
        test_scenario::end(scenario_val);
    }
}