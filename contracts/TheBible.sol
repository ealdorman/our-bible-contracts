/* solium-disable no-trailing-whitespace */

pragma solidity >= 0.5.0 < 0.6.0;
import './provableAPI_0.5.sol';
import './strings.sol';

/// @title Preserves verses from the KJV Bible on the blockchaib
/// @author John Wall, Ealdorman, Inc.
/// @notice Use this contract to store and retrieve Bible verses
/// @dev The oracle used here is provided by Provable at provable.xyz
contract TheBible is usingProvable {
  using strings for *;

  mapping(string => mapping(string => mapping(string => string))) verses;
  uint public versePrice;
  mapping(bytes32=>bool) validProvableQueryIds;
  address public owner;
  uint public provableGasLimit;
  /** @notice
   * At the point when all verses have been added, a user may read through all
   * verses by querying [book][chapter][verse], wherein the chapter and verse
   * are always incrementing numbers (as strings).
   * 
   * Therefore, all books names are added upon instantiation. To get all verses for
   * John, for example, a user need only query incrementing chapter and verse numbers
   * until he receives an undefined value (once all verses have been added).
   * */
  string[66] books = [
    '1 Chronicles',
    '1 Corinthians',
    '1 John',
    '1 Kings',
    '1 Peter',
    '1 Samuel',
    '1 Thessalonians',
    '1 Timothy',
    '2 Chronicles',
    '2 Corinthians',
    '2 John',
    '2 Kings',
    '2 Peter',
    '2 Samuel',
    '2 Thessalonians',
    '2 Timothy',
    '3 John',
    'Acts',
    'Amos',
    'Colossians',
    'Daniel',
    'Deuteronomy',
    'Ecclesiastes',
    'Ephesians',
    'Esther',
    'Exodus',
    'Ezekiel',
    'Ezra',
    'Galatians',
    'Genesis',
    'Habakkuk',
    'Haggai',
    'Hebrews',
    'Hosea',
    'Isaiah',
    'James',
    'Jeremiah',
    'Job',
    'Joel',
    'John',
    'Jonah',
    'Joshua',
    'Jude',
    'Judges',
    'Lamentations',
    'Leviticus',
    'Luke',
    'Malachi',
    'Mark',
    'Matthew',
    'Micah',
    'Nahum',
    'Nehemiah',
    'Numbers',
    'Obadiah',
    'Philemon',
    'Philippians',
    'Proverbs',
    'Psalms',
    'Revelation',
    'Romans',
    'Ruth',
    'Song of Solomon',
    'Titus',
    'Zechariah',
    'Zephaniah'
  ];

  /// @notice Limits access to Provable contracts
  modifier onlyProvable() {
    require(msg.sender == provable_cbAddress(), 'Callback did not originate from Provable');

    _;
  }
  
  /// @notice Limits access to the address from which the contract was created
  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract creator may interact with this function');
    
    _;
  }

  event LogNewProvableQuery(string description);
  event LogError(uint code);
  /// @dev The LogVerseAdded event is crucial for updating the off-chain database
  event LogVerseAdded(string book, string chapter, string verse);

  constructor() public {
    versePrice = 15000000000000000;
    
    owner = msg.sender;
    
    provableGasLimit = 500000;
  }

  /// @notice Takes a concatenated Bible verse reference and creates an oracle query
  /// @param concatenatedReference A Bible verse in the form of book/chapter/verse, i.e. John/3/16
  function setVerse(string memory concatenatedReference) public payable {
    require(
      msg.value >= versePrice,
      'Please send at least as much ETH as the versePrice with your transaction'
    );

    if (provable_getPrice("URL") > address(this).balance) {
      emit LogNewProvableQuery(
        "Provable query was NOT sent, please add some ETH to cover the Provable query fee"
      );
      
      emit LogError(1);

      revert('Address balance is not enough to cover Provable fee');
    }
    
    require(
      textIsEmpty(concatenatedReference) == false,
      'A concatenatedReference must be provided in the format book/chapter/verse'
    );

    bytes32 queryId = provable_query(
      "URL",
      "json(https://api.ourbible.io/verses/"
        .toSlice()
        .concat(concatenatedReference.toSlice())
        .toSlice()
        .concat(").provableText".toSlice()),
      provableGasLimit
    );
    
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer");

    validProvableQueryIds[queryId] = true;
  }

  /** @notice
   * Provable calls this function once it retrieves a query. The result is then
   * processed to break the book, chapter, verse and verse text. If the result 
   * is in the proper format, the verse is stored here in the contract. The
   * LogVerseAdded event is then called.
   */
  /// @dev This function is limited to calls from Provable
  /// @param myid The query ID provided by Provable
  /// @param result The result provided by Provable from the query
  function __callback(bytes32 myid, string memory result) public onlyProvable() {
    require(
      validProvableQueryIds[myid] == true,
      'ID not included in Provable valid IDs'
    );
    
    delete validProvableQueryIds[myid];

    string memory book;
    string memory chapter;
    string memory verse;
    string memory text;

    (book, chapter, verse, text) = processProvableText(result);

    verses[book][chapter][verse] = text;
    
    emit LogVerseAdded(book, chapter, verse);
  }

  /// @notice Splits the Provable result into its expected component parts or reverts if invalid
  /** @dev 
   * The result is expected be in the format: book---chapter---verse---text. If the result is not
   * in that format, the transaction will revert.
   */
  /// @param result A string retrieved from a Provable query
  function processProvableText(string memory result) public returns (
    string memory,
    string memory,
    string memory,
    string memory
  ) {
    require(
      textIsEmpty(result) == false,
      'The Provable result was empty.'
    );

    // The result should be in the format: book---chapter---verse---text
    
    strings.slice[4] memory parts;

    strings.slice memory full = result.toSlice();

    for (uint i = 0; i < 4; i++) {
      strings.slice memory part = full.split("---".toSlice());
        
      if (textIsEmpty(part.toString()) == true) {
        emit LogError(2);

        revert('Provable text was invalid.');
      }
      
      parts[i] = part;
    }

    return (
      parts[0].toString(),
      parts[1].toString(),
      parts[2].toString(),
      parts[3].toString()
    );
  }

  /// @notice Check to see if a string is empty
  /// @param _string A string for which to check whether it is empty
  /// @return a boolean value that expresses whether the string is empty
  function textIsEmpty(string memory _string) internal pure returns(bool) {
    return bytes(_string).length == 0;
  }

  /// @notice Retrieves a verse's text
  /// @param book The book name, all of which are listed in the books array
  /// @param chapter A chapter number, expressed as a string
  /// @param verse A verse number, express as a string
  /// @return Returns a verse's text if it has been stored
  function getVerse(
    string memory book,
    string memory chapter,
    string memory verse
  ) public view returns(string memory) {
    return verses[book][chapter][verse];
  }
  
  /// @notice Allows the contract's deployer to adjust the verse price
  /** @dev
   * The longest Bible verse, Esther 8:9, cost about 0.01 ETH at time of contract creation
   * due to Provable fees. 
   */
  /// @param _versePrice The price a user must pay to store a verse, denominated in wei
  function setVersePrice(uint _versePrice) public onlyOwner() {
    versePrice = _versePrice;
  }

  /// @notice Sets the gas limit of a Provable query
  /// @dev Because we're dealing with long strings, gas can be quite high
  /// @param _provableGasLimit An unsigned integer, denominated in gwei
  function setProvableGasLimit(uint _provableGasLimit) public onlyOwner() {
    provableGasLimit = _provableGasLimit;
  }
  
  /// @notice The contract's creator may withdraw any ETh accumulated in excess of Provable fees
  function withdraw() public onlyOwner() {
    msg.sender.transfer(address(this).balance);
  }
  
  /** @notice
   * A user does not have to interact with the setVerse function to store a Bible verse in
   * this contract. This fallback method allows a user to simply send ETH at least equal to
   * the versePrice, at which point a Provable query will be fired to fetch a random Bible
   * verse.
   */
  function() external payable {
    if (msg.value < versePrice) {
      emit LogError(3);
      
      return;
    }
   
    bytes32 queryId = provable_query(
      "URL",
      "json(https://api.ourbible.io/verses/random).provableText",
      provableGasLimit
    );
    
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer.");
    
    validProvableQueryIds[queryId] = true;
  }
}
