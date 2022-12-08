#[test_only]
module loyalty_gm::test_utils {
    use std::vector::{Self};

    use sui::test_scenario::{Self, Scenario};
    use sui::object::{Self};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem, AdminCap, VerifierCap};
    use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    use loyalty_gm::loyalty_token::{Self};

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

    //task
    const TASK_REWARD: u64 = 100;

    //reward
    const REWARD_LVL: u64 = 1;
    const REWARD_POOL_AMT: u64 = 1000;
    const REWARD_SUPPLY: u64 = 100;
    
    // ======== Utility functions =========

    // ======== Utility functions: Constants

    public fun get_ADMIN(): address {
        ADMIN
    }

    public fun get_VERIFIER(): address {
        VERIFIER
    }

    public fun get_USER_1(): address {
        USER_1
    }

    public fun get_USER_2(): address {
        USER_2
    }

    public fun get_LS_NAME(): vector<u8> {
        LS_NAME
    }

    public fun get_LS_DESCRIPTION(): vector<u8> {
        LS_DESCRIPTION
    }

    public fun get_LS_URL(): vector<u8> {
        LS_URL
    }

    public fun get_LS_MAX_SUPPLY(): u64 {
        LS_MAX_SUPPLY
    }

    public fun get_LS_MAX_LVL(): u64 {
        LS_MAX_LVL
    }

    public fun get_TASK_REWARD(): u64 {
        TASK_REWARD
    }

    public fun get_REWARD_LVL(): u64 {
        REWARD_LVL
    }

    public fun get_REWARD_POOL_AMT(): u64 {
        REWARD_POOL_AMT
    }

    public fun get_REWARD_SUPPLY(): u64 {
        REWARD_SUPPLY
    }

    // ======== Utility functions: Admin

    public fun mint_sui(scenario: &mut Scenario) {
        let coin = coin::mint_for_testing<SUI>(REWARD_POOL_AMT, test_scenario::ctx(scenario));
        transfer::transfer(coin, ADMIN);
    }

    public fun create_system_store(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            system_store::init_test(test_scenario::ctx(scenario));
        };
    }

    public fun create_loyalty_system(scenario: &mut Scenario, creator: address) {        
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

    public fun add_task(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::add_task(
                &admin_cap,
                &mut ls,
                b"name", 
                b"description", 
                TASK_REWARD, 
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

    public fun remove_task(scenario: &mut Scenario, task_id: object::ID) {
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

    public fun add_reward(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            
            loyalty_system::add_reward(
                &admin_cap,
                &mut ls,
                REWARD_LVL, 
                b"url reward", 
                b"reward description", 
                coin, 
                REWARD_SUPPLY,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    public fun remove_reward(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, ADMIN);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);

            loyalty_system::remove_reward(
                &admin_cap,
                &mut ls,
                REWARD_LVL,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    // ======== Utility functions: Verifier

    public fun get_verifier(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, VERIFIER);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);

            loyalty_system::get_verifier(test_scenario::ctx(scenario));
            
            test_scenario::return_shared(ls);
        };
    }

    public fun finish_task(scenario: &mut Scenario, user: address, task_id: object::ID) {
        test_scenario::next_tx(scenario, VERIFIER);
        {
            let ls = test_scenario::take_shared<LoyaltySystem>(scenario);
            let verify_cap = test_scenario::take_from_sender<VerifierCap>(scenario);

            loyalty_system::finish_task(
                &verify_cap,
                &mut ls,
                task_id,
                user
            );

            test_scenario::return_shared(ls);
            test_scenario::return_to_sender(scenario, verify_cap);
        };
    }

    // ======== Utility functions: User

    public fun mint_token(scenario: &mut Scenario, user: address) {
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

    public fun start_task(scenario: &mut Scenario, user: address, task_id: object::ID) {
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