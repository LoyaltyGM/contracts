module loyalty_gm::loyalty_system {
    friend loyalty_gm::loyalty_token;

    use std::vector::{length};
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use sui::vec_map::{Self, VecMap};
    use sui::table::{Table};
    use sui::dynamic_object_field as dof;
    use sui::coin::{Coin};
    use sui::sui::SUI;

    use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    use loyalty_gm::user_store::{Self, User};
    use loyalty_gm::reward_store::{Self, Reward};
    use loyalty_gm::task_store::{Self, Task};


    // ======== Constants =========
    const USER_STORE_KEY: vector<u8> = b"user_store";
    const MAX_NAME_LENGTH: u64 = 32;
    const MAX_DESCRIPTION_LENGTH: u64 = 255;
    const BASIC_MAX_LVL: u64 = 100;

    // ======== Error codes =========

    const EAdminOnly: u64 = 0;
    const ETextOverflow: u64 = 1;
    const EInvalidLevel: u64 = 2;
    const EMaxSupplyReached: u64 = 3;


    // ======== Structs =========

    struct AdminCap has key, store { 
        id: UID,
        loyalty_system: ID,
    }

    struct VerifierCap has key, store {
        id: UID,
    }
    
    struct LoyaltySystem has key {
        // collection
        id: UID,
        // Loyalty token name
        name: String,
        // Loyalty token description
        description: String,
        // Total number of NFTs that have been issued. 
        total_minted: u64,
        // Loyalty token total max supply
        max_supply: u64,
        // Loyalty token image url
        url: Url,
        creator: address,


        // tasks & rewards
        max_lvl: u64,
        // lvl_threshold: vector<u64>,
        tasks: VecMap<ID, Task>,
        rewards: VecMap<u64, Reward>,

        // --dynamic fields--
        // user_store: Table<address, User>,
    }

    // ======== Events =========

    struct CreateLoyaltySystemEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    // ======== Init =========
    fun init(ctx: &mut TxContext) {
        transfer::transfer(VerifierCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    // ======== Admin Functions =========

    public entry fun create_loyalty_system(
        name: vector<u8>, 
        description: vector<u8>, 
        url: vector<u8>,
        max_supply: u64,
        max_lvl: u64,
        system_store: &mut SystemStore<SYSTEM_STORE>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&name) <= MAX_NAME_LENGTH, ETextOverflow);
        assert!(length(&description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);
        assert!(max_lvl <= BASIC_MAX_LVL, EInvalidLevel);

        let creator = tx_context::sender(ctx);

        let loyalty_system = LoyaltySystem { 
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            total_minted: 0,
            max_supply,
            creator,
            max_lvl,
            tasks: task_store::empty(),
            rewards: reward_store::empty(),
        };
        dof::add(&mut loyalty_system.id, USER_STORE_KEY, user_store::new(ctx));

        emit(CreateLoyaltySystemEvent {
            object_id: object::uid_to_inner(&loyalty_system.id),
            creator,
            name: loyalty_system.name,
        });
        
        transfer::transfer(AdminCap { 
            id: object::new(ctx), 
            loyalty_system: object::uid_to_inner(&loyalty_system.id),
        }, creator);

        system_store::add_system(system_store, object::uid_to_inner(&loyalty_system.id), ctx);
        transfer::share_object(loyalty_system);
    }

    public entry fun update_name(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_name: vector<u8> ){
        assert!(length(&new_name) <= MAX_NAME_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.name = string::utf8(new_name);
    }

    public entry fun update_description(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_description: vector<u8> ){
        assert!(length(&new_description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.description = string::utf8(new_description);
    }

    public entry fun update_url(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_url: vector<u8> ){
        check_admin(admin_cap, loyalty_system);
        loyalty_system.url = url::new_unsafe_from_bytes(new_url);
    }

    public entry fun update_max_supply(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_max_supply: u64 ){
        check_admin(admin_cap, loyalty_system);
        loyalty_system.max_supply = new_max_supply;
    }

    public entry fun add_reward(
        admin_cap: &AdminCap, 
        loyalty_system: &mut LoyaltySystem,
        level: u64, 
        url: vector<u8>,
        description: vector<u8>, 
        reward_pool: Coin<SUI>,
        reward_supply: u64,
        ctx: &mut TxContext
    ) {
        check_admin(admin_cap, loyalty_system);
        assert!(level <= loyalty_system.max_lvl, EInvalidLevel);

        reward_store::add_reward(
            &mut loyalty_system.rewards, 
            level, 
            url,
            description,
            reward_pool,
            reward_supply,
            ctx
        );
    }

    public entry fun remove_reward(admin_cap: &AdminCap, level: u64, loyalty_system: &mut LoyaltySystem, ctx: &mut TxContext) {
        check_admin(admin_cap, loyalty_system);

        reward_store::remove_reward(&mut loyalty_system.rewards, level, ctx);
    }

    public entry fun add_task(
        admin_cap: &AdminCap, 
        loyalty_system: &mut LoyaltySystem,
        name: vector<u8>, 
        description: vector<u8>, 
        reward_xp: u64, 
        package_id: ID,
        module_name: vector<u8>,
        function_name: vector<u8>,
        arguments: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        check_admin(admin_cap, loyalty_system);

        task_store::add_task(
            &mut loyalty_system.tasks, 
            name, 
            description, 
            reward_xp,
            package_id,
            module_name,
            function_name,
            arguments,
            ctx,
        );
    }

    public entry fun remove_task(
        admin_cap: &AdminCap, 
        loyalty_system: &mut LoyaltySystem, 
        task_id: ID,
        _: &mut TxContext
    ) {
        check_admin(admin_cap, loyalty_system);

        task_store::remove_task(&mut loyalty_system.tasks, task_id);
    }

    public entry fun finish_task(
        _: &VerifierCap,
        loyalty_system: &mut LoyaltySystem, 
        task_id: ID, 
        user: address
    ) {
        let reward_xp = task_store::get_task_reward(&loyalty_system.tasks, &task_id);
        let user_store = get_mut_user_store(loyalty_system);
        user_store::finish_task(
            user_store,
            task_id,
            user,
            reward_xp
        )
    }


    // ======= User functions =======

    public entry fun start_task(loyalty_system: &mut LoyaltySystem, task_id: ID, ctx: &mut TxContext) {
        user_store::start_task(get_mut_user_store(loyalty_system), task_id, tx_context::sender(ctx))
    }

    // ======= Public functions =======

    public(friend) fun get_mut_user_store(loyalty_system: &mut LoyaltySystem): &mut Table<address, User>{
        dof::borrow_mut(&mut loyalty_system.id, USER_STORE_KEY)
    }

    public(friend) fun increment_total_minted(loyalty_system: &mut LoyaltySystem){
        assert!(get_total_minted(loyalty_system) <= get_max_supply(loyalty_system), EMaxSupplyReached);
        loyalty_system.total_minted = loyalty_system.total_minted + 1;
    }

    public(friend) fun get_mut_reward(loyalty_system: &mut LoyaltySystem, lvl: u64): &mut Reward{
        vec_map::get_mut(&mut loyalty_system.rewards, &lvl)
    }

    public fun get_name(loyalty_system: &LoyaltySystem): &string::String {
        &loyalty_system.name
    }

    public fun get_max_supply(loyalty_system: &LoyaltySystem): u64 {
        loyalty_system.max_supply 
    }

    public fun get_total_minted(loyalty_system: &LoyaltySystem): u64 {
        loyalty_system.total_minted
    }

    public fun get_description(loyalty_system: &LoyaltySystem): &string::String {
        &loyalty_system.description
    }

    public fun get_url(loyalty_system: &LoyaltySystem): &Url{
        &loyalty_system.url
    }

    public fun get_user_store(loyalty_system: &LoyaltySystem): &Table<address, User> {
        dof::borrow(&loyalty_system.id, USER_STORE_KEY)
    }

    public fun get_max_lvl(loyalty_system: &LoyaltySystem): u64 {
        loyalty_system.max_lvl
    }

    public fun get_tasks(loyalty_system: &LoyaltySystem): &VecMap<ID, Task> {
        &loyalty_system.tasks
    }

    public fun get_rewards(loyalty_system: &LoyaltySystem): &VecMap<u64, Reward> {
        &loyalty_system.rewards
    }

    // ======= Private/Utility functions =======

    fun check_admin(admin_cap: &AdminCap, system: &LoyaltySystem) {
        assert!(object::borrow_id(system) == &admin_cap.loyalty_system, EAdminOnly);
    }

    #[test_only]
    public fun check_admin_test(admin_cap: &AdminCap, system: &LoyaltySystem) {
        check_admin(admin_cap, system)
    }

    #[test_only]
    public fun get_verifier(ctx: &mut TxContext) {
        transfer::transfer(VerifierCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    public fun get_claimable_xp_test(ls: &LoyaltySystem, user: address): u64 {
        user_store::get_user_xp(get_user_store(ls), user)
    }
}