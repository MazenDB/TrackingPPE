pragma solidity =0.6.0;

contract Registration{
    
    address owner;
    
    mapping(address=>bool) manufacturers;
    mapping(address=>bool) distributors;
    mapping(address=>bool) wholesalers;
    mapping(address=>bool) retailers;
    
    modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }   
    
    constructor() public{
        owner=msg.sender;
    }
    
    function registerManufacturer(address m) public onlyOwner{
        require(!manufacturers[m],
        "Manufacturer exists already"
        );
        
        manufacturers[m]=true;
    }
    
    function registerDistributor(address d) public onlyOwner{
        require(!distributors[d],
        "Distributor exists already"
        );
        
        distributors[d]=true;
    }
    
    function registerWholeSaler(address w) public onlyOwner{
        require(!wholesalers[w],
        "WholeSaler exists already"
        );
        
        wholesalers[w]=true;
    }
    
    function registerRetailer(address r) public onlyOwner{
        require(!retailers[r],
        "Retailer exists already"
        );
        
        retailers[r]=true;
    }
    
    function isOwner(address o) public view returns(bool){
        return (owner==o);
    }
    
    function manufacturerExist(address m) public view returns(bool){
        return manufacturers[m];
    }
    
    function distributorExist(address d) public view returns(bool){
        return distributors[d];
    }
    
    function wholesalerExist(address w) public view returns(bool){
        return wholesalers[w];
    }
    
    function retailerExist(address r) public view returns(bool){
        return retailers[r];
    }
    
}


contract Lot{
    
    address productID;
    string productName;
    string materialHash;
    string batchNumber;
    string CECertificateHash;
    uint public totalQuantity;
    uint public remainingQuantity;
    
    string ownerType;
    address owner;
    Registration RegistrationContract;
    
    event LotDispatched (address productID, string productName, string materialHash, string batchNumber, string CECertificateHash);
    event OwnershipTransferred (address NewOwner, string ownerType);
    event SaletToRetailer (address productID, address retailerAddress, uint quantitySold);
    
    modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }   
    

    modifier onlyWholeSaler{
      require(RegistrationContract.wholesalerExist(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    constructor(address reigstration, address ID, string memory name, string memory material, string memory batch, string memory CE, uint quantity) public{
        RegistrationContract = Registration(reigstration);
        
        if(!RegistrationContract.manufacturerExist(msg.sender))
            revert("Sender not authorized.");
        
        owner=msg.sender;
        productID=ID;
        productName=name;
        materialHash=material;
        batchNumber=batch;
        CECertificateHash=CE;
        totalQuantity=quantity;
        remainingQuantity=totalQuantity;
        
        emit LotDispatched(address(this), productName, materialHash, batchNumber, CECertificateHash);
    }
    
    function transferOwnership (address newOwner) public onlyOwner{
        if(RegistrationContract.manufacturerExist(newOwner))
        ownerType="Manufacturer";
        else if(RegistrationContract.distributorExist(newOwner))
        ownerType="Distributor";
        else if(RegistrationContract.wholesalerExist(newOwner))
        ownerType="WholeSaler";
        else if(RegistrationContract.retailerExist(newOwner))
        ownerType="Retailer";
        else
        revert("New Owner doesn't exist.");
        owner=newOwner;
        emit OwnershipTransferred(owner,ownerType);
    }
    
    function sellToRetailer(address retailer, uint quantityToSell) public onlyWholeSaler{
        require(remainingQuantity>=quantityToSell,
        "Not enough Items available"
        );
        require(RegistrationContract.retailerExist(retailer),
        "Retailer does not exist"
        );
        
        remainingQuantity-=quantityToSell;
        
        emit SaletToRetailer(address(this),retailer,quantityToSell);
        
    } 

}


contract OrderManager{
    
    Registration RegistrationContract;
    
    struct order{
        address manufacturer;
        address wholesaler;
        address productID;
        uint quantity;
        bool orderConfirmed;
        bool orderReceived;
    }
    
    mapping(bytes32=>order) orders;
    modifier onlyOwner{
      require(RegistrationContract.isOwner(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    modifier onlyWholeSaler{
      require(RegistrationContract.wholesalerExist(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    modifier onlyManufacturer{
      require(RegistrationContract.manufacturerExist(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    event OrderPlaced (address manufacturer, address wholesaler, address productID, uint quantity);

    event OrderConfirmed (bytes32 orderID);

    event OrderReceived (bytes32 orderID);


    constructor(address reigstration) public{
        RegistrationContract = Registration(reigstration);
        
        if(!RegistrationContract.isOwner(msg.sender))
            revert("Sender not authorized");
        
    }
    
    function placeOrder(address productID, uint quantity, address manufacturer) public onlyWholeSaler{
        bytes32 temp=keccak256(abi.encodePacked(msg.sender,now,address(this),productID));
        orders[temp]=order(manufacturer,msg.sender,productID,quantity,false,false);
        
        emit OrderPlaced(manufacturer,msg.sender,productID,quantity);
    }
    
    function confirmOrder(bytes32 orderID) public onlyManufacturer{
        require(orders[orderID].manufacturer==msg.sender,
        "Sender not authorized."
        );
        
        orders[orderID].orderConfirmed=true;
        
        emit OrderConfirmed(orderID);
    }
    
    function confirmReceiving(bytes32 orderID) public onlyWholeSaler{
        require(orders[orderID].wholesaler==msg.sender,
        "Sender not authorized."
        );
        orders[orderID].orderReceived=true;
        
        emit OrderReceived(orderID);
    }

}
