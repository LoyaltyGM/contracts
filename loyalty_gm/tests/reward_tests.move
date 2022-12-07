#[test_only]
module loyalty_gm::reward_tests {
    use std::debug::print;

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map::{Self};

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem};
    use loyalty_gm::system_tests::{
        create_loyalty_system_test, 
    };
    use loyalty_gm::test_utils::{
        get_ADMIN,
        add_reward,
        remove_reward
    };

    // ======== Errors =========

    const Error: u64 = 1;

    // ======== Tests: Reward
    #[test]
    fun add_reward_test(): (Scenario) {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        add_reward(scenario);

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_rewards(&ls)) == 1, Error);
            let (_, reward)= vec_map::get_entry_by_idx(loyalty_system::get_rewards(&ls), 0);
            print(reward);

            test_scenario::return_shared(ls);
        };

        scenario_val
    }

    #[test]
    fun remove_reward_test() {
        let scenario_val = add_reward_test();
        let scenario = &mut scenario_val;

        remove_reward(scenario);

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_rewards(&ls)) == 0, Error);

            test_scenario::return_shared(ls);
        };

        test_scenario::end(scenario_val);
    }
}