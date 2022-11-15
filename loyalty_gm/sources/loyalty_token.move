module loyalty_gm::loyalty_token {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::url::{Url};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use loyalty_gm::loyalty_system::{Self, AdminCap, LoyaltySystem};

    // ======== Constants =========

    const BASIC_LEVEL: u8 = 0;
    const CURRENT_POINTS: u128 = 0;

    // ======== Error codes =========

    const ELevel: u64 = 0;
    const ETooManyMint: u64 = 1;
    const EAdminOnly: u64 = 2;

    // ======== Structs =========

    /// Loyalty NFT.
    struct LoyaltyToken has key, store {
        id: UID,
        loyalty_system: ID,
        name: String,
        description: String,
        url: Url,

        // Level of nft [0-255]
        level: u8,
        // Expiration timestamp (UNIX time) - app specific
        currentPointsXP: u128,
        // TODO:
        // array of lvl points 
        // pointsToNextLvl: u128,
    }

    // ======== Events =========

    struct MintTokenEvent has copy, drop {
        object_id: ID,
        loyalty_system:ID,
        minter: address,
        name: string::String,
    }

    // ======= Public functions =======

    public entry fun mint(
        ls: &mut LoyaltySystem,
        ctx: &mut TxContext
    ) {
        let n = *loyalty_system::get_issued_counter(ls);
        loyalty_system::increment_issued_counter(ls);
        
        let max_supply = *loyalty_system::get_max_supply(ls);
        assert!(n <= max_supply, ETooManyMint);

        let nft = LoyaltyToken {
            id: object::new(ctx),
            loyalty_system: object::id(ls),
            name: *loyalty_system::get_name(ls),
            description: *loyalty_system::get_description(ls),
            url: *loyalty_system::get_url(ls),
            level: BASIC_LEVEL,
            currentPointsXP: CURRENT_POINTS,
        };
        let sender = tx_context::sender(ctx);

        emit(MintTokenEvent {
            object_id: object::uid_to_inner(&nft.id),
            loyalty_system: object::id(ls),
            minter: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);
    }

    public fun current_lvl(nft: &mut LoyaltyToken): &u8 {
        &nft.level
    }

    // ======== Admin Functions =========

    public entry fun update_lvl(admin_cap: &AdminCap, token: &mut LoyaltyToken, _: &mut TxContext) {
        assert!(&token.loyalty_system == loyalty_system::get_system_by_admin_cap(admin_cap), EAdminOnly);
        token.level = token.level + 1;
    }

    // ======= Private and Utility functions =======

    fun check_admin(admin_cap: &AdminCap, token: &LoyaltyToken) {
        assert!(&token.loyalty_system == loyalty_system::get_system_by_admin_cap(admin_cap), EAdminOnly);
    }
}