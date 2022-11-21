module referal_system::token {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::object_table::{ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use std::option::{Self, Option, some};
    use referal_system::store::{Self, UserData};

    // ======== Constants =========

    const NAME: vector<u8> = b"LoyaltyGM";
    const DESCRIPTION: vector<u8> = b"SoulboundToken Test for Loyalty Rewards Platform on Sui Blockchain";
    const URL: vector<u8> = b"ipfs://QmVGYBzXTVzZFhJjtsd8bwBNJZ5drWwFF9XwsQJHFdbTkL";

    const INITIAL_REF_COUNTER: u64 = 0;
    const INITIAL_EXP: u64 = 0;
    
    // ======== Error codes =========

    const ENotUniqueAddress: u64 = 0;
    const EInvalidReferal: u64 = 1;
    const ENoClaimableExp: u64 = 2;

    // ======== Structs =========

    /// Loyalty Soulbound Token.
    struct SoulboundToken has key {
        id: UID,
        name: String,
        description: String,
        url: String,
        // minted with referal or not
        ref_id: Option<address>,
        // number of nfts
        ref_counter: u64,
        // current points
        current_exp: u64,
    }

    // ======== Events =========

    // EVENT MINT
    struct MintTokenEvent has copy, drop {
        token_id: ID,
        minter: address,
        name: string::String,
    }

    struct ClaimExpEvent has copy, drop {
        token_id: ID,
        claimer: address,
        claimed_exp: u64,
    }

    // ======= INITIALIZATION =======


    // ======= Public functions =======

    public entry fun claim_exp (
        token: &mut SoulboundToken, 
        table: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let claimable_exp = store::get_data_exp(table, sender);

        assert!(claimable_exp > 0, ENoClaimableExp);

        emit(ClaimExpEvent {
            token_id: object::id(token),
            claimer: sender,
            claimed_exp: claimable_exp,
        });

        store::reset_data_exp(table, sender);

        update_token_ref_counter(token);
        update_token_exp(claimable_exp, token);
    }

    public entry fun mint(
        store: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        mint_internal(option::none(), store, ctx);
    }

    public entry fun mint_with_ref (
        ref_address: address,
        table: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) != ref_address, EInvalidReferal);

        mint_internal(some(ref_address), table, ctx);
        
        if (store::user_exists(table, ref_address)) {
            store::update_data_exp(table, ref_address)
        };
    }

    // ======= Private and Utility functions =======

    fun mint_internal (
        ref_id: Option<address>,
        table: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        assert!(store::user_exists(table, tx_context::sender(ctx)) == false, ENotUniqueAddress);

        let sender = tx_context::sender(ctx);

        let nft = SoulboundToken {
            id: object::new(ctx),
            name: string::utf8(NAME),
            description: string::utf8(DESCRIPTION),
            url: string::utf8(URL),
            ref_id: ref_id,
            ref_counter: INITIAL_REF_COUNTER,
            current_exp: INITIAL_EXP,
        };
        
        emit(MintTokenEvent {
            token_id: object::id(&nft),
            minter: sender,
            name: nft.name,
        });

        store::add_new_data(table, object::id(&nft), ctx);
        transfer::transfer(nft, sender);
    }

    // work with token

    fun update_token_exp(exp_to_add: u64, token: &mut SoulboundToken) {
        token.current_exp = token.current_exp + exp_to_add;
    }

    fun update_token_ref_counter(token: &mut SoulboundToken) {
        token.ref_counter = token.ref_counter + 1;
    }
}