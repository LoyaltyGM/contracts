module loyalty_gm::loyalty_nft {
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};


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

    // ======== Admin Functions =========

    fun init(ctx: &mut TxContext,
        name: vector<u8>, 
        description: vector<u8>, 
        url: vector<u8>,
        max_supply: u64  
    ){
        transfer::transfer(LoyaltyManagerCap { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::share_object(LoyaltySystem { 
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: string::utf8(url),
            issued_counter: 0,
            max_supply: max_supply,
        })
    }

    // entry fun update_loyalty_system_name(loyalty_system: &mut LoyaltySystem, new_name: vector<u8> ){

    // }


    // ======= User functions =======

    /// Create a new devnet_nft
    public entry fun mint(
        loyaltySystem: &mut LoyaltySystem,
        ctx: &mut TxContext
    ) {
        let n = loyaltySystem.issued_counter;
        loyaltySystem.issued_counter = n + 1;
        assert!(n<=loyaltySystem.max_supply, ETooManyMint);

        let nft = LoyaltyToken {
            id: object::new(ctx),
            name: loyaltySystem.name,
            description: loyaltySystem.name,
            url: loyaltySystem.name,
            level: BASIC_LEVEL,
            currentPointsXP: CURRENT_POINTS,
        };
        let sender = tx_context::sender(ctx);

        transfer::transfer(nft, sender);
    }

    public entry fun update_lvl(nft: &mut LoyaltyToken, new_lvl: u8, _: &mut TxContext) {
        assert!(nft.level + 1 == new_lvl, ELevel);
        nft.level = new_lvl
    }

    public fun current_lvl(nft: &mut LoyaltyToken): &u8 {
        &nft.level
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
