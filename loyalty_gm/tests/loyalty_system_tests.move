#[test_only]
module loyalty_gm::loyalty_gm_tests {
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
    use std::vector::{Self};
    use std::debug::print;

    use sui::test_scenario::{Self, Scenario};
    use sui::url::{Self};
    use sui::vec_map::{Self};
    use sui::object::{Self};

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem, AdminCap, VerifierCap};
    use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    use loyalty_gm::loyalty_token::{Self, LoyaltyToken};

    // ======== Constants =========

    const ADMIN: address = @0xFACE;
    const VERIFIER: address = @0xCACA;
    const USER_1: address = @0xAA;
    const USER_2: address = @0xBB;

    const LS_NAME: vector<u8> = b"Loyalty System Name"; 
    const LS_DESCRIPTION: vector<u8> = b"Loyalty System Description";
    const LS_URL: vector<u8> = b"https://www.loyalty.com";
    const LS_MAX_SUPPLY: u64 = 100;
    const LS_MAX_LVL: u64 = 10;

    const TASK_REWARD: u64 = 100;

    // ======== Errors =========

    const Error: u64 = 1;

    // ======== Tests =========
    
    #[test]
    fun create_loyalty_system_test(): Scenario {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        create_system_store(scenario);
        create_loyalty_system(scenario, ADMIN);

        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            
            assert!(*loyalty_system::get_name(&ls) == string::utf8(LS_NAME), Error);
            assert!(*loyalty_system::get_description(&ls) == string::utf8(LS_DESCRIPTION), Error);
            assert!(*loyalty_system::get_url(&ls) == url::new_unsafe_from_bytes(LS_URL), Error);
            assert!(loyalty_system::get_max_supply(&ls) == LS_MAX_SUPPLY, Error);
            assert!(loyalty_system::get_max_lvl(&ls) == LS_MAX_LVL, Error);

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

        test_scenario::next_tx(scenario, ADMIN);
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

        create_loyalty_system(scenario, USER_1);

        test_scenario::next_tx(scenario, ADMIN);
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

    // ======== Tests: Tasks

    #[test]
    fun add_task_test(): (Scenario, object::ID) {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;
        let task_id: object::ID;

        add_task(scenario);

        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_tasks(&ls)) == 1, Error);
            let (id, _)= vec_map::get_entry_by_idx(loyalty_system::get_tasks(&ls), 0);
            // print(loyalty_system::get_tasks(&ls));
            task_id = *id;
            print(id);

            test_scenario::return_shared(ls);
        };

        (scenario_val, task_id)
    }

    #[test]
    fun finish_task_test(): Scenario {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        get_verifier(scenario);

        mint_token(scenario, USER_1);
        start_task(scenario, USER_1, task_id);

        finish_task(scenario, task_id);

        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(loyalty_system::get_claimable_xp_test(&ls, USER_1)== TASK_REWARD, Error);

            test_scenario::return_shared(ls);
        };

        scenario_val
    }

    #[test]
    fun remove_task_test() {
        let (scenario_val, task_id) = add_task_test();
        let scenario = &mut scenario_val;

        remove_task(scenario, task_id);

        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            assert!(vec_map::size(loyalty_system::get_tasks(&ls)) == 0, Error);

            test_scenario::return_shared(ls);
        };

        test_scenario::end(scenario_val);
    }

    // ======== Tests: Token

    #[test]
    fun mint_test(): Scenario {
        let scenario_val = create_loyalty_system_test();
        let scenario = &mut scenario_val;

        mint_token(scenario, USER_1);

        test_scenario::next_tx(scenario, USER_1);
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

        mint_token(scenario, USER_1);
        mint_token(scenario, USER_1);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun claim_xp_test() {
        let scenario_val = finish_task_test();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, USER_1);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let token = test_scenario::take_from_sender<LoyaltyToken>(scenario);

            loyalty_token::claim_xp(&mut ls, &mut token, test_scenario::ctx(scenario));

            assert!(loyalty_token::get_xp(&token) == TASK_REWARD, Error);

            test_scenario::return_to_sender(scenario, token);
            test_scenario::return_shared(ls);
        };
        
        test_scenario::end(scenario_val);
    }

    // ======== Utility functions =========

    // ======== Utility functions: Admin

    fun create_system_store(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            system_store::init_test(test_scenario::ctx(scenario));
        };
    }

    fun create_loyalty_system(scenario: &mut Scenario, creator: address) {        
        test_scenario::next_tx(scenario, creator);
        {
            let system_store = test_scenario::take_shared<SystemStore<SYSTEM_STORE>>(scenario);

            loyalty_system::create_loyalty_system(
                LS_NAME,
                LS_DESCRIPTION,
                LS_URL,
                LS_MAX_SUPPLY,
                LS_MAX_LVL,
                &mut system_store,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(system_store);
        };
    }

    fun add_task(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::add_task(
                &admin_cap,
                &mut ls,
                b"name", 
                b"description", 
                100, 
                object::id(&admin_cap),
                b"module",
                b"function_name",
                vector::empty(),
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    fun remove_task(scenario: &mut Scenario, task_id: object::ID) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::remove_task(
                &admin_cap,
                &mut ls,
                task_id,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    // ======== Utility functions: Verifier

    fun get_verifier(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, VERIFIER);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            loyalty_system::get_verifier(test_scenario::ctx(scenario));
            
            test_scenario::return_shared(ls);
        };
    }

    fun finish_task(scenario: &mut Scenario, task_id: object::ID) {
        test_scenario::next_tx(scenario, VERIFIER);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let verify_cap = test_scenario::take_from_sender<VerifierCap>(scenario);

            loyalty_system::finish_task(
                &verify_cap,
                &mut ls,
                task_id,
                USER_1
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, verify_cap);
        };
    }

    // ======== Utility functions: User

    fun mint_token(scenario: &mut Scenario, user: address) {
        test_scenario::next_tx(scenario, user);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            loyalty_token::mint(
                &mut ls,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
        };
    }

    fun start_task(scenario: &mut Scenario, user: address, task_id: object::ID) {
        test_scenario::next_tx(scenario, user);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            loyalty_system::start_task(
                &mut ls,
                task_id,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
        };
    }
}