module loyalty_gm::loyalty_system {
    friend loyalty_gm::loyalty_token;

    use std::vector::length;
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use sui::vec_map::{Self, VecMap};
    use sui::table::{Table};
    use sui::dynamic_object_field as ofield;

    use loyalty_gm::system_store::{Self, SystemStore, SYSTEM_STORE};
    use loyalty_gm::user_store::{Self, UserData};


    // ======== Constants =========
    const USER_STORE_KEY: vector<u8> = b"user_store";
    const MAX_NAME_LENGTH: u64 = 32;
    const MAX_DESCRIPTION_LENGTH: u64 = 255;
    const BASIC_REWARD_EXP: u64 = 5;
    const BASIC_MAX_LEVELS: u64 = 30;

    // ======== Error codes =========

    const EAdminOnly: u64 = 0;
    const ETextOverflow: u64 = 1;
    const EInvalidLevel: u64 = 3;


    // ======== Structs =========

    struct AdminCap has key, store {
        id: UID,
        loyalty_system: ID,
    }

    //TODO: rewards & tasks to modules
    struct LoyaltySystem has key {
        id: UID,
        // Loyalty token name
        name: String,
        // Loyalty token total max supply
        max_supply: u64,
        // Total number of NFTs that have been issued. 
        total_minted: u64,
        // Loyalty token description
        description: String,
        // Loyalty token image url
        url: Url,
        max_levels: u64,
        tasks: VecMap<u64, TaskInfo>,
        rewards: VecMap<u64, RewardInfo>,
        creator: address,

        // --dynamic fields--
        // user_store: Table<address, UserData>,
    }

    struct TaskInfo has store, drop {
        reward_exp: u64,
        description: String,
    }

    struct RewardInfo has store, drop {
        level: u64,
        description: String,
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

    // ======= Public functions =======

    public entry fun create_loyalty_system(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        max_supply: u64,
        system_store: &mut SystemStore<SYSTEM_STORE>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&name) <= MAX_NAME_LENGTH, ETextOverflow);
        assert!(length(&description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);

        let sender = tx_context::sender(ctx);

        let loyalty_system = LoyaltySystem {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            total_minted: 0,
            max_supply,
            creator: sender,
            max_levels: BASIC_MAX_LEVELS,
            tasks: vec_map::empty<u64, TaskInfo>(),
            rewards: vec_map::empty<u64, RewardInfo>(),
        };
        ofield::add(&mut loyalty_system.id, USER_STORE_KEY, user_store::create_store(ctx));

        emit(CreateLoyaltySystemEvent {
            object_id: object::uid_to_inner(&loyalty_system.id),
            creator: sender,
            name: loyalty_system.name,
        });

        transfer::transfer(AdminCap {
            id: object::new(ctx),
            loyalty_system: object::uid_to_inner(&loyalty_system.id),
        }, sender);

        system_store::add_system(system_store, object::uid_to_inner(&loyalty_system.id), ctx);
        transfer::share_object(loyalty_system);
    }

    public fun get_name(loyalty_system: &LoyaltySystem): &string::String {
        &loyalty_system.name
    }

    public fun get_max_supply(loyalty_system: &LoyaltySystem): &u64 {
        &loyalty_system.max_supply
    }

    public fun get_total_minted(loyalty_system: &LoyaltySystem): &u64 {
        &loyalty_system.total_minted
    }

    public fun get_description(loyalty_system: &LoyaltySystem): &string::String {
        &loyalty_system.description
    }

    public fun get_url(loyalty_system: &LoyaltySystem): &Url {
        &loyalty_system.url
    }

    public fun get_user_store(loyalty_system: &LoyaltySystem): &Table<address, UserData> {
        ofield::borrow(&loyalty_system.id, USER_STORE_KEY)
    }

    // ======== Admin Functions =========

    public entry fun update_loyalty_system_name(
        admin_cap: &AdminCap,
        loyalty_system: &mut LoyaltySystem,
        new_name: vector<u8>
    ) {
        assert!(length(&new_name) <= MAX_NAME_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.name = string::utf8(new_name);
    }

    public entry fun update_loyalty_system_description(
        admin_cap: &AdminCap,
        loyalty_system: &mut LoyaltySystem,
        new_description: vector<u8>
    ) {
        assert!(length(&new_description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.description = string::utf8(new_description);
    }

    public entry fun update_loyalty_system_url(
        admin_cap: &AdminCap,
        loyalty_system: &mut LoyaltySystem,
        new_url: vector<u8>
    ) {
        check_admin(admin_cap, loyalty_system);
        loyalty_system.url = url::new_unsafe_from_bytes(new_url);
    }

    public entry fun update_loyalty_system_max_supply(
        admin_cap: &AdminCap,
        loyalty_system: &mut LoyaltySystem,
        new_max_supply: u64
    ) {
        check_admin(admin_cap, loyalty_system);
        loyalty_system.max_supply = new_max_supply;
    }

    public entry fun add_reward_info(
        admin_cap: &AdminCap,
        level: u64,
        description: vector<u8>,
        loyalty_system: &mut LoyaltySystem,
        _: &mut TxContext
    ) {
        check_admin(admin_cap, loyalty_system);
        assert!(level <= loyalty_system.max_levels, EInvalidLevel);

        let reward_info = RewardInfo {
            level,
            description: string::utf8(description)
        };
        vec_map::insert(&mut loyalty_system.rewards, level, reward_info);
    }

    public entry fun remove_reward_info(
        admin_cap: &AdminCap,
        level: u64,
        loyalty_system: &mut LoyaltySystem,
        _: &mut TxContext
    ) {
        check_admin(admin_cap, loyalty_system);

        vec_map::remove(&mut loyalty_system.rewards, &level);
    }

    // ======= Private and Utility functions =======

    fun check_admin(admin_cap: &AdminCap, system: &LoyaltySystem) {
        assert!(object::borrow_id(system) == &admin_cap.loyalty_system, EAdminOnly);
    }

    public(friend) fun get_mut_user_store(loyalty_system: &mut LoyaltySystem): &mut Table<address, UserData> {
        ofield::borrow_mut(&mut loyalty_system.id, USER_STORE_KEY)
    }

    public(friend) fun increment_total_minted(loyalty_system: &mut LoyaltySystem) {
        loyalty_system.total_minted = loyalty_system.total_minted + 1;
    }
}