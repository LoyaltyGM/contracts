#[test_only]
module loyalty_gm::reward_tests {
    use std::debug::print;

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map::{Self};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem};
    use loyalty_gm::system_tests::{
        create_loyalty_system_test, 
    };
    use loyalty_gm::test_utils::{
        get_ADMIN,
        add_reward,
        remove_reward,
        get_USER_1,
        get_REWARD_LVL,
        claim_reward,
        add_fail_reward,
        add_single_reward,
        finish_task,
        start_task,
        get_REWARD_POOL_AMT,
        get_REWARD_SUPPLY,
        mint_token,
        get_verifier,
        get_USER_2,
        claim_xp,
    };
    use loyalty_gm::task_tests::{
        add_task_test,
    };
    use loyalty_gm::token_tests::{
        claim_xp_test
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
    #[expected_failure(abort_code = 0)]
    fun fail_add_reward_test() {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        add_fail_reward(scenario);

        test_scenario::end(scenario_val);
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

     #[test]
    fun claim_reward_test(): (Scenario) {
        let scenario_val = claim_xp_test();
        let scenario = &mut scenario_val;

        add_reward(scenario);
        claim_reward(scenario, get_USER_1(), get_REWARD_LVL());

        test_scenario::next_tx(scenario, get_USER_1());
        {
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);

            assert!(coin::value(&coin) == get_REWARD_POOL_AMT()/get_REWARD_SUPPLY(), Error);

            test_scenario::return_to_sender(scenario, coin);
        };

        scenario_val
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun fail_claim_reward_twice_test() {
        let scenario_val = claim_xp_test();
        let scenario = &mut scenario_val;

        add_reward(scenario);
        claim_reward(scenario, get_USER_1(), get_REWARD_LVL());
        claim_reward(scenario, get_USER_1(), get_REWARD_LVL());

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun fail_claim_exceeded_reward_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;
        get_verifier(scenario);


        mint_token(scenario, get_USER_1());
        start_task(scenario, get_USER_1(), task_id);
        finish_task(scenario, get_USER_1(), task_id);
        claim_xp(scenario, get_USER_1());

        mint_token(scenario, get_USER_2());
        start_task(scenario, get_USER_2(), task_id);
        finish_task(scenario, get_USER_2(), task_id);
        claim_xp(scenario, get_USER_2());

        add_single_reward(scenario);
        claim_reward(scenario, get_USER_1(), get_REWARD_LVL());
        claim_reward(scenario, get_USER_2(), get_REWARD_LVL());

        test_scenario::end(scenario_val);
    }
}