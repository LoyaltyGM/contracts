#[test_only]
module loyalty_gm::system_tests {
    // use std::vector::{length};
    // use std::string::{Self, String};

    // use sui::object::{Self, UID, ID};
    // use sui::transfer;
    // use sui::url::{Self, Url};
    // use sui::tx_context::{Self, TxContext};
    // use sui::event::{emit};
    // use sui::vec_map::{Self, VecMap};
    // use sui::table::{Table};
    // use sui::dynamic_object_field as dof;
    // use sui::coin::{Coin};
    // use sui::sui::SUI;
    // use sui::test_scenario::{Self, Scenario};

    // use loyalty_gm::loyalty_system::{Self, LoyaltySystem};
    // use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    // use loyalty_gm::user_store::{Self, User};
    // use loyalty_gm::reward_store::{Self, Reward};
    // use loyalty_gm::task_store::{Self, Task};
    
    // =================
    use std::string::{Self};

    use sui::test_scenario::{Self, Scenario};
    use sui::url::{Self};
    use sui::object::{Self};

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem, AdminCap};
    use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    use loyalty_gm::test_utils::{
        get_ADMIN,
        get_USER_1,
        get_LS_NAME,
        get_LS_DESCRIPTION,
        get_LS_URL,
        get_LS_MAX_SUPPLY,
        get_LS_MAX_LVL,
        mint_sui, 
        create_system_store, 
        create_loyalty_system,
    };

    // ======== Errors =========

    const Error: u64 = 1;

    // ======== Tests =========
    
    #[test]
    public fun create_loyalty_system_test(): Scenario {
        let scenario_val = test_scenario::begin(get_ADMIN());
        let scenario = &mut scenario_val;

        mint_sui(scenario);
        create_system_store(scenario);
        create_loyalty_system(scenario, get_ADMIN());

        test_scenario::next_tx(scenario, get_ADMIN());
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            
            assert!(*loyalty_system::get_name(&ls) == string::utf8(get_LS_NAME()), Error);
            assert!(*loyalty_system::get_description(&ls) == string::utf8(get_LS_DESCRIPTION()), Error);
            assert!(*loyalty_system::get_url(&ls) == url::new_unsafe_from_bytes(get_LS_URL()), Error);
            assert!(loyalty_system::get_max_supply(&ls) == get_LS_MAX_SUPPLY(), Error);
            assert!(loyalty_system::get_max_lvl(&ls) == get_LS_MAX_LVL(), Error);

            let store = test_scenario::take_shared<SystemStore<SYSTEM_STORE>>(scenario);
            
            assert!(system_store::contains(&store, object::id(&ls)), Error);
            
            test_scenario::return_shared(ls);
            test_scenario::return_shared(store);
        };

        scenario_val
    }

    #[test]
    fun update_loyalty_system_test() {
        let new_name = b"new name";
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, get_ADMIN());
        { 
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::update_name(
                &admin_cap,
                &mut ls,
                new_name,
            );
            assert!(*loyalty_system::get_name(&ls) == string::utf8(new_name), Error);

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun check_admin_cap_test() {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        create_loyalty_system(scenario, get_USER_1());

        test_scenario::next_tx(scenario, get_ADMIN());
        { 
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::check_admin_test(
                &admin_cap,
                &mut ls,
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        
        test_scenario::end(scenario_val);
    }
}