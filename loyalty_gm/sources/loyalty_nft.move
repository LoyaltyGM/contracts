module loyalty_gm::loyalty_nft {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};

    // Mint Level
    const BASIC_LEVEL: u8 = 0;
    const CURRENT_POINTS: u128 = 0;

    // Error codes
    const ELevel: u64 = 0;
    const ETooManyMint: u64 = 1;

    // Belongs to the creator
    struct LoyaltyManagerCap has key, store { id: UID }

    struct LoyaltySystem has key {
        id: UID,
        // Loyalty token name
        name: String,
        // Loyalty token total max supply
        max_supply: u64,
        // Total number of NFTs that have been issued. 
        issued_counter: u64,
         // Loyalty token description
        description: String,
        // Loyalty token image url
        url: String,
    }

    /// Loyalty NFT.
    struct LoyaltyToken has key, store {
        id: UID,
        name: String,
        description: String,
        url: String,

        // Level of nft [1-100]
        level: u8,
        // Expiration timestamp (UNIX time) - app specific
        currentPointsXP: u128,
        // TODO:
        // array of lvl points 
        // pointsToNextLvl: u128,
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

    struct MintToken has copy, drop {
        object_id: ID,
        loyalty_system:ID,
        minter: address,
        name: string::String,
    }

    // ======== Admin Functions =========

    public entry fun create_loyalty_system(
        name: vector<u8>, 
        description: vector<u8>, 
        url: vector<u8>,
        max_supply: u64,
        ctx: &mut TxContext,
    ){
        let loyalty_system = LoyaltySystem { 
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: string::utf8(url),
            issued_counter: 0,
            max_supply: max_supply,
        };
        let sender = tx_context::sender(ctx);

        emit(CreateLoyaltySystemEvent {
            object_id: object::uid_to_inner(&loyalty_system.id),
            creator: sender,
            name: loyalty_system.name,
        });
        transfer::transfer(LoyaltyManagerCap { id: object::new(ctx) }, sender);
        transfer::share_object(loyalty_system)
    }

    public entry fun update_loyalty_system_name(_: &LoyaltyManagerCap, loyalty_system: &mut LoyaltySystem, new_name: vector<u8> ){
        loyalty_system.name = string::utf8(new_name);
    }

    public entry fun update_loyalty_system_description(_: &LoyaltyManagerCap, loyalty_system: &mut LoyaltySystem, new_description: vector<u8> ){
        loyalty_system.description = string::utf8(new_description);
    }

    public entry fun update_loyalty_system_url(_: &LoyaltyManagerCap, loyalty_system: &mut LoyaltySystem, new_url: vector<u8> ){
        loyalty_system.url = string::utf8(new_url);
    }

    public entry fun update_loyalty_system_max_supply(_: &LoyaltyManagerCap, loyalty_system: &mut LoyaltySystem, new_max_supply: u64 ){
        loyalty_system.max_supply = new_max_supply;
    }

    // ======= Public functions =======

    /// Create a new devnet_nft
    public entry fun mint(
        loyalty_system: &mut LoyaltySystem,
        ctx: &mut TxContext
    ) {
        let n = loyalty_system.issued_counter;
        loyalty_system.issued_counter = n + 1;
        assert!(n<=loyalty_system.max_supply, ETooManyMint);

        let nft = LoyaltyToken {
            id: object::new(ctx),
            name: loyalty_system.name,
            description: loyalty_system.description,
            url: loyalty_system.url,
            level: BASIC_LEVEL,
            currentPointsXP: CURRENT_POINTS,
        };
        let sender = tx_context::sender(ctx);

        emit(MintToken {
            object_id: object::uid_to_inner(&nft.id),
            loyalty_system: object::id(loyalty_system),
            minter: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);
    }

    public entry fun update_lvl(nft: &mut LoyaltyToken, new_lvl: u8, _: &mut TxContext) {
        assert!(nft.level + 1 == new_lvl, ELevel);
        nft.level = new_lvl
    }

    public fun current_lvl(nft: &mut LoyaltyToken): &u8 {
        &nft.level
    }

    public fun get_name(loyalty_system: &LoyaltySystem): &string::String{
        &loyalty_system.name
    }

    public fun get_max_supply(loyalty_system: &LoyaltySystem): &u64{
        &loyalty_system.max_supply
    }

    public fun get_issued_counter(loyalty_system: &LoyaltySystem): &u64{
        &loyalty_system.issued_counter
    }

    public fun get_description(loyalty_system: &LoyaltySystem): &string::String{
        &loyalty_system.description
    }

    public fun get_url(loyalty_system: &LoyaltySystem): &string::String{
        &loyalty_system.url
    }

    // ======= Private and Utility functions =======


}

// #[test_only]
// module sui::loyalty_nftTest {
//     // use sui::devnet_nft::{Self, DevNetNFT};
//     use sui::test_scenario as ts;
//     use sui::transfer;
//     use std::debug::{print};
//     use nfts::loyalty_nft::{Self, LoyaltyToken};

//     #[test]
//     fun mint_transfer_update() {
//         let addr1 = @0xA;
//         let addr2 = @0xB;

//         let newLvl: u8 = 1; 
//         // create the NFT
//         let scenario = ts::begin(addr1);
//         {
//             loyalty_nft::mint(b"test", b"https://www.sui.io", ts::ctx(&mut scenario))
//         };
//         // send it from A to B
//         ts::next_tx(&mut scenario, addr1);
//         {
//             let nft = ts::take_from_sender<LoyaltyToken>(&mut scenario);
//             transfer::transfer(nft, addr2);
//         };
//         // update its description
//         ts::next_tx(&mut scenario, addr2);
//         {
//             let nft = ts::take_from_sender<LoyaltyToken>(&mut scenario);
//             print(loyalty_nft::currentLvl(&mut nft));
//             loyalty_nft::update_lvl(&mut nft, newLvl, ts::ctx(&mut scenario));
//             print(loyalty_nft::currentLvl(&mut nft));
//             assert!(loyalty_nft::currentLvl(&mut nft) == &newLvl, 0);
//             ts::return_to_sender(&mut scenario, nft);
//         };
//         ts::end(scenario);
//     }
// }
