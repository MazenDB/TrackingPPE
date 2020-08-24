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
    
    //address productID;
    string productName;
    string materialHash;
    string batchNumber;
    uint timestamp;
    string CECertificateHash;
    uint totalQuantity;
    uint remainingQuantity;
    
    string ownerType;
    address owner;
    Registration RegistrationContract;
    
    event LotDispatched (address productID, string productName, string materialHash, string batchNumber, uint timestamp, string CECertificateHash);
    event OwnershipTransferred (address NewOwner, string ownerType);
    event SaletToRetailer (address productID, address retailerAddress, uint quantitySold);
    
    modifier onlyOwner{
      require(msg.sender == owner,
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
    
    modifier onlyWholeSaler{
      require(RegistrationContract.wholesalerExist(msg.sender),
      "Sender not authorized."
      );
      _;
    }   
    
    constructor(address reigstration,string memory product, string memory material, string memory batch, string memory CE, uint quantity) public{
        RegistrationContract = Registration(reigstration);
        
        if(!RegistrationContract.manufacturerExist(msg.sender))
            revert("Sender not authorized.");
        
        owner=msg.sender;
        productName=product;
        materialHash=material;
        batchNumber=batch;
        timestamp=now;
        CECertificateHash=CE;
        totalQuantity=quantity;
        remainingQuantity=totalQuantity;
        
        emit LotDispatched(address(this), productName, materialHash, batchNumber, timestamp, CECertificateHash);
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