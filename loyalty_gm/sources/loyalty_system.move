module loyalty_gm::loyalty_system {
    friend loyalty_gm::loyalty_token;

    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use sui::object_table::{ObjectTable};
    use std::vector::length;
    use loyalty_gm::system_store::{Self, LoyaltySystemData};
    use loyalty_gm::user_store::{Self};

    // ======== Constants =========

    const MAX_NAME_LENGTH: u64 = 32;
    const MAX_DESCRIPTION_LENGTH: u64 = 255;

    // ======== Error codes =========

    const EAdminOnly: u64 = 0;
    const ETextOverflow: u64 = 1;

    // ======== Structs =========

    struct AdminCap has key, store { 
        id: UID,
        loyalty_system: ID
    }

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
        creator: address,
        user_store: ID
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
        system_store: &mut ObjectTable<ID, LoyaltySystemData>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&name) <= MAX_NAME_LENGTH, ETextOverflow);
        assert!(length(&description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);

        let sender = tx_context::sender(ctx);
        let user_store_id = user_store::create_store(ctx);

        let loyalty_system = LoyaltySystem { 
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            total_minted: 0,
            max_supply: max_supply,
            creator: sender,
            user_store: user_store_id,
        };

        emit(CreateLoyaltySystemEvent {
            object_id: object::uid_to_inner(&loyalty_system.id),
            creator: sender,
            name: loyalty_system.name,
        });
        
        transfer::transfer(AdminCap { id: object::new(ctx), loyalty_system: object::uid_to_inner(&loyalty_system.id) }, sender);
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

    public fun get_url(loyalty_system: &LoyaltySystem): &Url{
        &loyalty_system.url
    }

    public fun get_user_store_id(loyalty_system: &LoyaltySystem): &ID {
        &loyalty_system.user_store
    }

    public fun get_system_by_admin_cap(admin_cap: &AdminCap): &ID {
        &admin_cap.loyalty_system
    }

    // ======== Admin Functions =========

    public entry fun update_loyalty_system_name(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_name: vector<u8> ){
        assert!(length(&new_name) <= MAX_NAME_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.name = string::utf8(new_name);
    }

    public entry fun update_loyalty_system_description(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_description: vector<u8> ){
        assert!(length(&new_description) <= MAX_DESCRIPTION_LENGTH, ETextOverflow);
        check_admin(admin_cap, loyalty_system);
        loyalty_system.description = string::utf8(new_description);
    }

    public entry fun update_loyalty_system_url(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_url: vector<u8> ){
        check_admin(admin_cap, loyalty_system);
        loyalty_system.url = url::new_unsafe_from_bytes(new_url);
    }

    public entry fun update_loyalty_system_max_supply(admin_cap: &AdminCap, loyalty_system: &mut LoyaltySystem, new_max_supply: u64 ){
        check_admin(admin_cap, loyalty_system);
        loyalty_system.max_supply = new_max_supply;
    }

    // ======= Private and Utility functions =======

    fun check_admin(admin_cap: &AdminCap, system: &LoyaltySystem) {
        assert!(object::borrow_id(system) == &admin_cap.loyalty_system, EAdminOnly);
    }

    public(friend) fun increment_total_minted(loyalty_system: &mut LoyaltySystem){
        loyalty_system.total_minted = loyalty_system.total_minted + 1;
    }
}