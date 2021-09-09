// SPDX-License-Identifier: MIT
/** 
██████╗ ███████╗████████╗██████╗  ██████╗      ██████╗ █████╗ ████████╗███████╗    
██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    
██████╔╝█████╗     ██║   ██████╔╝██║   ██║    ██║     ███████║   ██║   ███████╗    
██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║    ██║     ██╔══██║   ██║   ╚════██║    
██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝    ╚██████╗██║  ██║   ██║   ███████║    
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    
                                                                                   
███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗               
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗              
██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║              
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║              
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║              
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝              
                                                                          
<<https://github.com/retro-cats/retro-cats-contracts>>

*/
pragma solidity 0.8.3;
/*
* @title Our contract for storing cat data.
*/
contract RetroCatsMetadata {
    uint256 internal s_maxChanceValue = 10000;
    struct RetroCat {
        Background background;
        Frame frame;
        Breed breed;
        Eyes eyes;
        Hair hair;
        Bling bling;
        Head head;
        Item item;
        Ring ring;
        Earring earring;
        Vice vice; 
    }
    /**
    * @dev Percentages for each trait
    * @dev each row will always end with 10000
    * When picking a trait based on RNG, we will get a value between 0 - 99999
    * We choose the trait based on the sum of the integers up to the index
    * For example, if my random number is 251, and my array is [250, 200, 10000]
    *      This means my trait is at the 1st index. 251 is higher than 250, but lower than
    *      250 + 200
    */

    uint256 internal s_totalTraits = 11;
    enum Background{Black, Blue, Green, Grey, Orange, Pink, Purple, Red, Yellow}
    uint256[] internal S_BACKGROUND_METADATA = [200, 1000, 500, 1000, 1000, 2300, 1000, 2000, 1000, s_maxChanceValue];
    enum Frame{Black, Brass, Browne, Glit, Gold, Leather, Pine, Silver, White, Wood, None}
    uint256[] internal S_FRAME_METADATA = [250, 150, 300, 200, 40, 10, 80, 70, 400, 100, 8400, s_maxChanceValue];
    enum Breed{Bengal, Calico, Chimera, HighColor, Mitted, Solid, Tabby, Tortie, Tuxedo, Van}
    uint256[] internal S_BREED_METADATA = [90, 1200, 10, 1000, 1400, 2000, 1800, 700, 1300, 500, s_maxChanceValue];
    enum Eyes{BlueOpen, BlueWink, Closed, GreenOpen, GreenWink, OrangeOpen, OrangeWink, YellowOpen, YellowWink}
    uint256[] internal S_EYES_METADATA = [1200, 10, 2000, 1400, 90, 1800, 1000, 1600, 900, s_maxChanceValue];    
    enum Hair{ Braid, Dreads, Fro, LongFlipped, LongStraight, Mullet, Muttonchops, Pageboy, ShortFlipped, None }
    uint256[] internal S_HAIR_METADATA = [1300, 90, 1000, 1200, 1400, 10, 600, 900, 1700, 1800, s_maxChanceValue];
    enum Bling{BlueNeckscarf, CopperBracelet, DiscoChest, HandlebarMustache, LongMustache, LoveBeads, MoonNecklaces, PeaceNecklace, PearlNecklace, PukaShellNecklace}
    uint256[] internal S_BLING_METADATA = [1100, 1200, 800, 1000, 500, 700, 1400, 400, 1300,1600, s_maxChanceValue];
    enum Head{AviatorGlasses, Daisy, Eyepatch, Headband, Headscarf, HeartGlasses, NewsboyCap, RoundGlasses, SquareGlasses, TopHat}
    uint256[] internal S_HEAD_METADATA = [1200, 1500, 200, 1300, 600, 300, 1600, 1000, 1400, 900, s_maxChanceValue];
    enum Item{Atari, Disco, Ether, FlooyDisc, Houseplants, LandscapePainting, LavaLamp, PalmSurboard, Record, RedGuitar}
    uint256[] internal S_ITEM_METADATA = [90, 1000, 10, 2000, 1200, 900, 1300, 600, 1500, 1400, s_maxChanceValue];
    enum Ring{Emerald, MoodBlue, MoodGreen, MoodPurple, MoodRed, Onyx, Ruby, Sapphire, Tortoiseshell, Turquoise}
    uint256[] internal S_RING_METADATA = [1200, 1000, 1000, 1000, 1000, 1200, 1200, 1200, 500, 700, s_maxChanceValue];
    enum Earring{Coral, DiamondStuds, GoldBobs, GoldChandelier, GoldHoops, OrangeWhite, RubyStuds, SilverHoops, Tortoiseshell, Turquoise, None}
    uint256[] internal S_EARRING_METADATA = [400, 10, 200, 90, 1200, 500, 700, 1000, 300, 600, 5000, s_maxChanceValue];
    enum Vice{Beer, Bong, Cigarette, Eggplant, JelloSalad, Joint, Mushrooms, PetRock, PurpleBagOfCoke, Whiskey}
    uint256[] internal S_VICE_METADATA = [1400, 900, 1500, 1300, 90, 1200, 2000, 10, 600, 1000, s_maxChanceValue];

    uint256[][] public S_TRAIT_ARRAYS = [S_BACKGROUND_METADATA, S_FRAME_METADATA, S_BREED_METADATA, S_EYES_METADATA, S_HAIR_METADATA, S_BLING_METADATA, S_HEAD_METADATA, S_ITEM_METADATA, S_RING_METADATA, S_EARRING_METADATA, S_VICE_METADATA];

    string public purr = "Meow!";

    function rngToCat(uint256 randomNumber) public view returns (RetroCat memory retroCat){
    // function rngToCat(uint256 randomNumber) public view returns (uint256){
        uint256[][] memory traitArrays = S_TRAIT_ARRAYS;
        uint256[] memory traitIndexes = new uint256[](s_totalTraits);
        for (uint i = 0; i < s_totalTraits; i++){
            uint256 traitIndex = getTraitIndex(traitArrays[i], getModdedRNG(randomNumber, i));
            traitIndexes[i] = traitIndex;
        }
        // retroCat = RetroCat(Background(traitIndexes[0]),Frame(1),Breed(1),Eyes(1),Hair(1),Bling(1),Head(1),Item(1),Ring(1),Earring(1),Vice(1));
        retroCat = RetroCat({
            background: Background(traitIndexes[0]),
            frame: Frame(traitIndexes[1]),
            breed: Breed(traitIndexes[2]),
            eyes: Eyes(traitIndexes[3]),
            hair: Hair(traitIndexes[4]),
            bling: Bling(traitIndexes[5]),
            head: Head(traitIndexes[6]),
            item: Item(traitIndexes[7]),
            ring: Ring(traitIndexes[8]),
            earring: Earring(traitIndexes[9]),
            vice: Vice(traitIndexes[10])
        });
    }

    function getModdedRNG(uint256 randomNumber, uint256 seed) public view returns(uint256 modded_rng){
        uint256 newRng = uint256(keccak256(abi.encode(randomNumber, seed)));
        modded_rng = newRng % s_maxChanceValue;
    }

    function getTraitIndex(uint256[] memory traitArray, uint256 moddedRNG) public pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the s_maxChanceValue");
    }
}
