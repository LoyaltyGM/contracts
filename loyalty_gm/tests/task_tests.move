#[test_only]
module loyalty_gm::task_tests {
    use std::debug::print;

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map::{Self};
    use sui::object::{Self};

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem};
    use loyalty_gm::system_tests::{
    create_loyalty_system_test,
    };
    use loyalty_gm::test_utils::{
    get_ADMIN,
    get_USER_1,
    get_TASK_REWARD,
    add_task,
    get_verifier,
    mint_token,
    start_task,
    finish_task,
    remove_task,
    };

    // ======== Errors =========

    const Error: u64 = 1;

    // ======== Tests: Tasks

    #[test]
    public fun add_task_test(): (Scenario, object::ID) {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;
        let task_id: object::ID;

        add_task(scenario);

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_tasks(&ls)) == 1, Error);
            let (id, _) = vec_map::get_entry_by_idx(loyalty_system::get_tasks(&ls), 0);
            // print(loyalty_system::get_tasks(&ls));
            task_id = *id;
            print(id);

            test_scenario::return_shared(ls);
        };

        (scenario_val, task_id)
    }

    #[test]
    public fun finish_task_test(): Scenario {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        get_verifier(scenario);

        mint_token(scenario, get_USER_1());
        start_task(scenario, get_USER_1(), task_id);

        finish_task(scenario, get_USER_1(), task_id);

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(loyalty_system::get_claimable_xp_test(&ls, get_USER_1()) == get_TASK_REWARD(), Error);

            test_scenario::return_shared(ls);
        };

        scenario_val
    }

    #[test]
    #[expected_failure(abort_code = loyalty_gm::user_store::ETaskAlreadyDone)]
    public fun fail_start_task_twice_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        get_verifier(scenario);

        mint_token(scenario, get_USER_1());
        start_task(scenario, get_USER_1(), task_id);

        finish_task(scenario, get_USER_1(), task_id);

        start_task(scenario, get_USER_1(), task_id);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = loyalty_gm::user_store::ETaskAlreadyDone)]
    public fun fail_finish_task_twice_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        get_verifier(scenario);

        mint_token(scenario, get_USER_1());
        start_task(scenario, get_USER_1(), task_id);

        finish_task(scenario, get_USER_1(), task_id);
        finish_task(scenario, get_USER_1(), task_id);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = loyalty_gm::user_store::ETaskNotStarted)]
    public fun fail_finish_not_started_task_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        get_verifier(scenario);
        mint_token(scenario, get_USER_1());

        finish_task(scenario, get_USER_1(), task_id);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun remove_task_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        remove_task(scenario, task_id);

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_tasks(&ls)) == 0, Error);

            test_scenario::return_shared(ls);
        };

        test_scenario::end(scenario_val);
    }
}