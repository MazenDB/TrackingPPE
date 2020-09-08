pragma solidity =0.6.0;

contract Registration{
    
    address owner;
    
    mapping(address=>bool) manufacturers;
    mapping(address=>bool) distributors;
    mapping(address=>bool) wholesalers;
    mapping(address=>bool) providers;
    
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
    
    function registerProvider(address p) public onlyOwner{
        require(!providers[p],
        "Provider exists already"
        );
        
        providers[p]=true;
    }
    
    function isOwner(address o) public view returns(bool){
        return (owner==o);
    }
    
    function manufacturerExists(address m) public view returns(bool){
        return manufacturers[m];
    }
    
    function distributorExists(address d) public view returns(bool){
        return distributors[d];
    }
    
    function wholesalerExists(address w) public view returns(bool){
        return wholesalers[w];
    }
    
    function providerExists(address p) public view returns(bool){
        return providers[p];
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
    event SaletToProvider (address productID, address providerAddress, uint quantitySold);
    
    modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }   
    

    modifier onlyWholeSaler{
      require(RegistrationContract.wholesalerExists(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    constructor(address registration, address ID, string memory name, string memory material, string memory batch, string memory CE, uint quantity) public{
        RegistrationContract = Registration(registration);
        
        if(!RegistrationContract.manufacturerExists(msg.sender))
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
        if(RegistrationContract.manufacturerExists(newOwner))
        ownerType="Manufacturer";
        else if(RegistrationContract.distributorExists(newOwner))
        ownerType="Distributor";
        else if(RegistrationContract.wholesalerExists(newOwner))
        ownerType="WholeSaler";
        else if(RegistrationContract.providerExists(newOwner))
        ownerType="Provider";
        else
        revert("New Owner doesn't exist.");
        owner=newOwner;
        emit OwnershipTransferred(owner,ownerType);
    }
    
    function sellToProvider(address provider, uint quantityToSell) public onlyWholeSaler{
        require(remainingQuantity>=quantityToSell,
        "Not enough Items available"
        );
        require(RegistrationContract.providerExists(provider),
        "Provider does not exist"
        );
        
        remainingQuantity-=quantityToSell;
        
        emit SaletToProvider(address(this),provider,quantityToSell);
        
    } 

}


contract OrderManager{
    
    Registration RegistrationContract;
    
    enum status{
        Pending,
        Accepted,
        Rejected,
        Received
    }
    
    struct order{
        address manufacturer;
        address wholesaler;
        address productID;
        uint quantity;
        status orderStatus;
    }
    
    mapping(bytes32=>order) orders;
    modifier onlyOwner{
      require(RegistrationContract.isOwner(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    modifier onlyWholeSaler{
      require(RegistrationContract.wholesalerExists(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    modifier onlyManufacturer{
      require(RegistrationContract.manufacturerExists(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    event OrderPlaced (address manufacturer, address wholesaler, address productID, uint quantity);

    event StatusUpdated (bytes32 orderID, status newStatus);

    event OrderReceived (bytes32 orderID);


    constructor(address reigstration) public{
        RegistrationContract = Registration(reigstration);
        
        if(!RegistrationContract.isOwner(msg.sender))
            revert("Sender not authorized");
        
    }
    
    function placeOrder(address productID, uint quantity, address manufacturer) public onlyWholeSaler{
        require(RegistrationContract.manufacturerExists(manufacturer),
        "Manufacturer address is not valid");
        bytes32 temp=keccak256(abi.encodePacked(msg.sender,now,address(this),productID));
        orders[temp]=order(manufacturer,msg.sender,productID,quantity,status.Pending);
        
        emit OrderPlaced(manufacturer,msg.sender,productID,quantity);
    }
    
    function confirmOrder(bytes32 orderID, bool accepted) public onlyManufacturer{
        require(orders[orderID].manufacturer==msg.sender,
        "Sender not authorized."
        );
        if(accepted){
            orders[orderID].orderStatus=status.Accepted;
        }
        else{
            orders[orderID].orderStatus=status.Rejected;
        }
        emit StatusUpdated(orderID,orders[orderID].orderStatus);

    }
    
    function confirmReceived(bytes32 orderID) public onlyWholeSaler{
        require(orders[orderID].wholesaler==msg.sender,
        "Sender not authorized."
        );
        orders[orderID].orderStatus=status.Received;
        
        emit OrderReceived(orderID);
    }

}
