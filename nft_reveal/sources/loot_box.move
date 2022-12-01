module nft_reveal::loot_box {
    use movemate::pseudorandom::{Self};

    use std::string::{Self, String};
    use std::vector;

    use sui::event::{emit};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    // ======== Constants =========
    const LOW_RANGE: u64 = 1;
    const HIGH_RANGE: u64 = 100;
    const BOX_URL: vector<u8> = b"ipfs://QmZVAXP7B7ZukhCDR5uSivmagkY53QtGZnvPRgZtEjfZrv";
    const LOOT_URL: vector<u8> =  b"ipfs://QmVGYBzXTVzZFhJjtsd8bwBNJZ5drWwFF9XwsQJHFdbTkL";

    // ======== Errors =========

    const EAmountIncorrect: u64 = 0;
    const EMaxSupplyReaced: u64 = 1;

    // ======== Events =========

    struct BuyBoxEvent has copy, drop {
        box_id: ID,
        buyer: address,
    }

    struct OpenBoxEvent has copy, drop {
        box_id: ID,
        loot_id: ID,
        opener: address,
    }
    
    // ======== Structs =========

    struct BoxCollection has key {
        id: UID,
        creator: address,
        box_max_supply: u64,
        box_url: Url,
        box_price: u64,
        rarity_types: vector<String>,
        rarity_weights: vector<u64>,
        // changable
        _box_minted: u64,
        _box_opened: u64,
    }

    struct LootBox has key, store {
        id: UID,
        name: String,
        url: Url,
    }

    struct Loot has key, store {
        id: UID,
        name: String,
        rarity: String,
        score: u64,
        url: Url
    }

    // ======== Init =========

    fun rarity_type(): vector<String> {
       let rarity_types = vector::empty<String>();
        vector::push_back(&mut rarity_types, string::utf8(b"Common"));
        vector::push_back(&mut rarity_types, string::utf8(b"Rare"));
        vector::push_back(&mut rarity_types, string::utf8(b"Epic"));
        rarity_types 
    }

    fun rarity_weight(): vector<u64> {
        let rarity_weights = vector::empty<u64>();
        vector::push_back(&mut rarity_weights, 70);
        vector::push_back(&mut rarity_weights, 25);
        vector::push_back(&mut rarity_weights, 5);
        rarity_weights
    }

    fun init(ctx: &mut TxContext) {
        let rarity_types = rarity_type();

        let rarity_weights = rarity_weight();
        
        let collection = BoxCollection {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            box_max_supply: 1000,
            box_url: url::new_unsafe_from_bytes(BOX_URL),
            box_price: 10000000,
            rarity_types: rarity_types,
            rarity_weights: rarity_weights,
            _box_minted: 0,
            _box_opened: 0,
        };

        transfer::share_object(collection);
    }

    // ======== Public functions =========

    public fun owner(collection: &BoxCollection): address {
        collection.creator
    }

    public fun get_box_minted(collection: &BoxCollection): u64 {
        collection._box_minted
    }

    public fun get_box_opened(collection: &BoxCollection): u64 {
        collection._box_opened
    }

    public entry fun buy_box(
        collection: &mut BoxCollection, 
        paid: Coin<SUI>, 
        ctx: &mut TxContext
    ) {
        let n = collection._box_minted + 1;
        let sender = tx_context::sender(ctx);

        assert!(n < collection.box_max_supply, EMaxSupplyReaced);
        assert!(collection.box_price == coin::value(&paid), EAmountIncorrect);
        
        let box = LootBox {
            id: object::new(ctx),
            name: string::utf8(b"Mystery Box"),
            url: url::new_unsafe_from_bytes(BOX_URL),
        };

        emit(BuyBoxEvent {
            box_id: object::id(&box),
            buyer: sender,
        });

        collection._box_minted = n;
        transfer::transfer(box, sender);
        transfer::transfer(paid, collection.creator);
    }

    public entry fun open_box(collection: &mut BoxCollection, box: LootBox, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let LootBox{ id, name: _, url: _ } = box;

        let loot = get_loot(collection, ctx);

        emit(OpenBoxEvent {
            box_id: object::uid_to_inner(&id),
            loot_id: object::id(&loot),
            opener: sender
        });

        collection._box_opened = collection._box_opened + 1;
        object::delete(id);
        transfer::transfer(loot, sender)
    }

    // ======== Private functions =========

    fun get_loot(collection: &mut BoxCollection, ctx: &mut TxContext): Loot {
        let score = get_loot_score(ctx);
        let rarity = get_loot_rarity(score, collection);
        Loot {
            id: object::new(ctx),
            name: string::utf8(b"LOOT!!"),
            rarity: rarity,
            score: score,
            url: url::new_unsafe_from_bytes(LOOT_URL)
        }
    }

    fun get_loot_score(ctx: &mut TxContext): u64 {
        pseudorandom::rand_u64_range_with_ctx(LOW_RANGE, HIGH_RANGE + 1, ctx)
    }

    fun get_loot_rarity(score: u64, collection: &mut BoxCollection): String {
        let types = collection.rarity_types;
        let weights = collection.rarity_weights;
        
        let result_rarity = *vector::borrow(&types, 0);
        
        let r = score + HIGH_RANGE;
        let length = vector::length(&weights);
        let i = 0;
        loop {
            if (i >= length) break;
            r = r - *vector::borrow(&weights, i);
            if (r <= HIGH_RANGE) {
                result_rarity = *vector::borrow(&types, i);
                break
            };
            i = i + 1;
        };
        
        result_rarity
    }
    // https://stackoverflow.com/questions/74513153/test-for-init-function-from-examples-doesnt-works
    #[test_only]
    public fun create_lootbox(ctx: &mut TxContext) {
        let rarity_types = rarity_type();
        let rarity_weights = rarity_weight();

        let collection = BoxCollection {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            box_max_supply: 1000,
            box_url: url::new_unsafe_from_bytes(BOX_URL),
            box_price: 10000000,
            rarity_types: rarity_types,
            rarity_weights: rarity_weights,
            _box_minted: 0,
            _box_opened: 0,
        };

        transfer::share_object(collection);
        
    }
}
