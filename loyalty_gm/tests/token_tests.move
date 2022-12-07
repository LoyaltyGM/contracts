#[test_only]
module loyalty_gm::token_tests {
    use std::debug::print;

    use sui::test_scenario::{Self, Scenario};

    use loyalty_gm::loyalty_system::{LoyaltySystem};
    use loyalty_gm::loyalty_token::{Self, LoyaltyToken};
    use loyalty_gm::test_utils::{mint_token};
    use loyalty_gm::system_tests::{
        create_loyalty_system_test, 
    };
    use loyalty_gm::task_tests::{
        finish_task_test,
    };
    use loyalty_gm::test_utils::{
        get_USER_1,
        get_TASK_REWARD,
    };

    // ======== Errors =========

    const Error: u64 = 1;

    // ======== Tests: Token

    #[test]
    fun mint_test(): Scenario {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        mint_token(scenario, get_USER_1());

        test_scenario::next_tx(scenario, get_USER_1());
        {
            let token = test_scenario::take_from_sender<LoyaltyToken>(scenario);

            print(&token);

            test_scenario::return_to_sender(scenario, token);
        };

        scenario_val
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun mint_test_fail() {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        mint_token(scenario, get_USER_1());
        mint_token(scenario, get_USER_1());

        test_scenario::end(scenario_val);
    }

    #[test]
    fun claim_xp_test() {
        let scenario_val = finish_task_test();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, get_USER_1());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let token = test_scenario::take_from_sender<LoyaltyToken>(scenario);

            loyalty_token::claim_xp(&mut ls, &mut token, test_scenario::ctx(scenario));

            assert!(loyalty_token::get_xp(&token) == get_TASK_REWARD(), Error);

            test_scenario::return_to_sender(scenario, token);
            test_scenario::return_shared(ls);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun fail_claim_xp_test() {
        let scenario_val = mint_test();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, get_USER_1());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let token = test_scenario::take_from_sender<LoyaltyToken>(scenario);

            loyalty_token::claim_xp(&mut ls, &mut token, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, token);
            test_scenario::return_shared(ls);
        };
        
        test_scenario::end(scenario_val);
    }
}