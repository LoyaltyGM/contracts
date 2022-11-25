module nft_reveal::nft_box {
    use sui::event;
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use std::vector;
    use movemate::pseudorandom::{Self};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    // ======== Constants =========

    const INITIAL_COUNTER: u64 = 0;

    const COMMON_SUPPLY: u64 = 1000;
    const COMMON_PRICE: u64= 10000000; // Coin
    const COMMON_URL: vector<u8> = b"ipfs://QmZVAXP7B7ZukhCDR5uSivmagkY53QtGZnvPRgZtEjfZrv";

    const LOOT_URL: vector<u8> =  b"ipfs://QmVGYBzXTVzZFhJjtsd8bwBNJZ5drWwFF9XwsQJHFdbTkL";

    // ======== Errors =========

    const EAmountIncorrect: u64 = 0;

    //TODO: add weighted selection for various boxes

    // ======== Structs =========

    struct BoxesStorage has key {
        id: UID,
        owner: address,
        common_boxes_counter: u64,
        // rare_boxes_counter: u64,
        // epic_boxes_counter: u64,
    }

    struct Box has key, store {
        id: UID,
        name: String,
        // type: u8
        // description: String,
        url: Url,
    }

    struct Loot has key, store {
        name: String,
        // description: String,
        rarity: u64,
        url: Url
    }

    // ======== Init =========

    fun init(ctx: &mut TxContext) {
        let storage = BoxesStorage {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            common_boxes_counter: INITIAL_COUNTER,
            // rare_boxes_counter: INITIAL_COUNTER,
            // epic_boxes_counter: INITIAL_COUNTER,
        };

        transfer::share_object(storage);
    }

    // ======== Public functions =========

    public entry fun buy_box(storage: &mut BoxesStorage, paid: Coin<SUI>, ctx: &mut TxContext) {
        assert!( COMMON_PRICE == coin::value(&paid), EAmountIncorrect);

        transfer::transfer(Box {
            id: object::new(ctx),
            name: string::utf8(b"Common box"),
            url: url::new_unsafe_from_bytes(COMMON_URL),
        }, tx_context::sender(ctx));

        transfer::transfer(paid, storage.owner);
    }

    public entry fun open_box(box: Box, ctx: &mut TxContext) {
        let Box{ id, name, url } = box;
        object::delete(id);

        transfer::transfer(Loot {
            name: string::utf8(b"Loot"),
            rarity: pseudorandom::rand_u64_range_with_ctx(1, 100, ctx),
            url: url::new_unsafe_from_bytes(LOOT_URL),
        }, tx_context::sender(ctx));
    }

    // ======== Private functions =========

}