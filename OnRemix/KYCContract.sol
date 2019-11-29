pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract KYCContract {
  
    address admin;
    
    /*
    Struct for a customer
     */
    struct Customer {
        string userName;   //unique
        string data_hash;  //unique
        uint8 customerUpvotes;
        address bank;
        uint   customerRating;					 
        string customerPassword;
    }

    /*
    Struct for a Bank
     */
    struct Bank {
        address ethAddress;   //unique  
        string bankName;
        string regNumber;       //unique
        uint   bankRating;	
		uint   bankUpvotes ;
		uint   bank_KYC_count;
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;     
        string data_hash;  //unique
        address bank;
        bool    isAllowed;
    }
    KYCRequest[] public allKYCRequests;

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    string[] customerNames;
    Customer[] public allCustomers;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    address[] bankAddresses;
    Bank[] public allBanks;

   struct customerRating{ address bankAddress;
						   string customerName;
						}
						
    struct bankRating{ address existingBankAddressInChain;
                       address bankAddressToValidate;
    		 }	
	customerRating[] public allCustomerRatings;
	bankRating[] public allBankRatings;

    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }

    /**
     * This method checks if a Bank already exists in the chain or no.
     */
    function isBankInChain(address _bankAddr) internal view returns(bool){
		for(uint i=0;i<allBanks.length;i++){
	    	  if (allBanks[i].ethAddress==_bankAddr){
				   return true;
			  }
        } 
		return false;   
	}
	/**
     * This method addes a bank , but will check if it exists or no , only if the bank not there, then only add it to chain.
     * However, this method should be accessable by only the admin or allowed personal , so it will check the tigger node and then allow it.
     */
	function addBank(string memory _bankName,address _bankAddr,string memory _bankRegNum) public payable validateCallingNode returns(uint){
			   
		 require(!isBankInChain(_bankAddr),'Bank already exists with same address!!!!');
					 
		 allBanks.push(Bank({bankName:_bankName,ethAddress:_bankAddr,regNumber:_bankRegNum,bank_KYC_count: 0, bankRating: 0, bankUpvotes :0}));
		 
		 if(isBankInChain(_bankAddr)){
			return 1;
		 }
			return 0;
		}
	
	/**
     * This method removes a bank from chain , but will check if it exists or no , if its not there , not to remove from chain.
     * However, this method should be accessable by only the admin or allowed personal , so it will check the tigger node and then allow it.
     */
	function removeBank(address _bankAddr) public payable validateCallingNode returns(uint){
		require(isBankInChain(_bankAddr),'No Bank exists with the address passed!!!!');
			 
		for(uint i=0;i<allBanks.length;i++){
			  if (allBanks[i].ethAddress==_bankAddr){
				   allBanks[i] = allBanks[allBanks.length];
				   delete allBanks[allBanks.length];
				   allBanks.length--;
				   return 1;
			    }
			} 
		return 0;   	
	}
		
	/**
     * This method addes a bank , but will check if it exists or no , only if the bank not there, then only add it to chain.
     * However, this method should be accessable by only the admin or allowed personal , so it will check the tigger node and then allow it.
     */
	modifier validateCallingNode(){
		require(msg.sender == admin, "Only Admin or allowed Node can access this function");
		_;
	}	
		
    /**
     * this function adds a kyc request for a customer into a bank.
     * however, it will check if that customer is already having a kyc request already added to bank or not.
     * And it will check if the bank has enough rating to accept the request or no.
     */
    function addKycRequest(string memory _userName, string memory _customerData) public payable returns (uint8) {
        require(!isKYCAlreadyExists(_userName),'This users request is already in system');
        bool    bankRatedWell;
		address customerBankAddress;
		
		for(uint i=0;i<allCustomers.length;i++){
			 if (stringsEquals(allCustomers[i].userName,_userName)){
			 	 customerBankAddress = allCustomers[i].bank;
				 for(uint k=0;k<allBanks.length;k++){
					if((allBanks[k].ethAddress==allCustomers[i].bank)){
					     allBanks[k].bank_KYC_count++;	
						if (allBanks[k].bankRating > 50)
						  bankRatedWell=true;																				  																			  
						else
						  bankRatedWell=false;  
					}
				 
				 }
			 }
		 }
        allKYCRequests.push(KYCRequest({userName:_userName,data_hash:_customerData,bank:customerBankAddress,isAllowed:bankRatedWell}));
		for(uint i=0;i<allKYCRequests.length;i++){
		    if (stringsEquals(allKYCRequests[i].userName,_userName)){
			   return 1;
			}
		} 
		return 0;   
    }

    /**
     * Add a new custome
     */
    function addCustomer(string memory _userName, string memory _customerData) public payable returns (uint8) {
        //require(doesBankExists(),'The Bank doesnt access new Customer.');
		require(!isCustomerValid(_userName),' This customer already exists.');
		allCustomers.push(Customer({ 
		                  userName: _userName,
						  data_hash: _customerData,
						  customerRating  :0,
						  customerUpvotes : 0,
						  bank    : msg.sender,
						  customerPassword:'0'
						  })
		);
		for(uint i=0;i<allCustomers.length;i++){
			 if (stringsEquals(allCustomers[i].userName,_userName)){
				 return 1;
			 }
    	 }
		return 0;   
	}
	
	/**
	 * This function sets passwrod for the cuscustomerPassword
	 */
    function setPassword(string memory customerName,string memory password) public returns (bool)
    {
        require(isCustomerValid(customerName),'Not an existing customer to assign a password.');
		for(uint i=0;i<allCustomers.length;i++){
		    if (stringsEquals(allCustomers[i].userName,customerName)){
		        allCustomers[i].customerPassword = password;
		        allCustomers[i].bank = msg.sender;
		        return true;
		    }
	    }
		return false;  
    }
    
    /**
     * Remove KYC request
     */
    function removeKYCRequest(string memory _userName) public payable  returns (uint8) {
        require(isKYCAlreadyExists(_userName),'No KYC Request in system for this user.');
        for(uint i=0;i<allKYCRequests.length;i++){
			if (stringsEquals(allKYCRequests[i].userName,_userName)){
				allKYCRequests[i]=allKYCRequests[allKYCRequests.length];
				delete allKYCRequests[allKYCRequests.length];
				allKYCRequests.length--;
				return 1;
			}
		}
        return 0; 
    }

    /**
     * Remove customer information
     * 
     */
    function removeCustomer(string memory _userName) public payable  returns (uint8) {
        require(isCustomerValid(_userName),'There is no customer with this name');
		for(uint i=0;i<allCustomers.length;i++){
			if (stringsEquals(allCustomers[i].userName,_userName)){
				allCustomers[i]=allCustomers[allCustomers.length];
				delete allCustomers[allCustomers.length];
				allCustomers.length--;
				return 1;
			}
		}
    	return 0;   
    }

    /**
     * Edit customer information
     */
    function modifyCustomer(string memory _userName,string memory password, string memory _newcustomerData) public payable  returns (uint8) {
        require(isCustomerValid(_userName),'Not an existing customer');
	    
	    // Check whether the password passed is null or not 
		bytes memory passwordToCheck = bytes(password); 			
		if (passwordToCheck.length == 0)
           password = '0';
                   
		for(uint i=0;i<allCustomers.length;i++){
		 
		      bytes storage existingPWD = bytes(allCustomers[i].customerPassword); 
 		      if (existingPWD.length == 0)
                  allCustomers[i].customerPassword = '0';
                       
			if (stringsEquals(allCustomers[i].userName,_userName) && stringsEquals(allCustomers[i].customerPassword,password)){
			   allCustomers[i].data_hash = _newcustomerData;
			   allCustomers[i].bank = msg.sender;
			   allCustomers[i].customerRating = 0;
			   allCustomers[i].customerUpvotes= 0;
			   allCustomers.length--;
			   return 1;
			}
		}            
		return 0;
    }

    /**
     * View customer information
     * 
     */
    function viewCustomer(string memory _userName, string memory password) public returns (string memory) {
        
       	bytes memory passwordToCheck = bytes(password); 			
		if (passwordToCheck.length == 0)
           password = '0';
           
		for(uint i=0;i<allCustomers.length;i++){
		    bytes storage existingPWD = bytes(allCustomers[i].customerPassword); 
 		      if (existingPWD.length == 0)
                  allCustomers[i].customerPassword = '0';
                  
			 if (stringsEquals(allCustomers[i].userName,_userName)  && stringsEquals(allCustomers[i].customerPassword,password) ){
				return allCustomers[i].data_hash;
			}
		}

    }

    /**
     * Add a new upvote to customer
     * 
     */
    function UpvoteCustomer(string memory _userName) public payable  returns (uint8) {
        require(isCustomerValid(_userName),'Not an existing customer !!!');
        require(!checkCustomereRating(msg.sender), 'This Customer has been upvoted already.');
        
         for(uint i=0;i<allCustomers.length;i++){
			 if (stringsEquals(allCustomers[i].userName,_userName)){
				 allCustomers[i].customerUpvotes++;
				 
				 allCustomers[i].customerRating = (allCustomers[i].customerUpvotes/allBanks.length)*100;
				 allCustomers[i].bank = msg.sender;
				 
				 if (allCustomers[i].customerRating > 50){
					  allCustomerRatings.push(customerRating({bankAddress: msg.sender, customerName: _userName}));
					  return 1;
				}
			}
	    }
    }
    
    function upVoteBank(address _bankAddr) public payable  returns (uint){
		
	  require(isBankValid(_bankAddr),'No Bank exists with this address.');
	  require(!checkBankRating(msg.sender), 'You have already upvoted for this Bank!!!!!!!!');
								  
	  for(uint i=0;i<allBanks.length;i++){
		 if (allBanks[i].ethAddress == _bankAddr){
			 allBanks[i].bankUpvotes++;                                                                     
			 allBanks[i].bankRating = (allBanks[i].bankUpvotes/allBanks.length)*100;
			 allBankRatings.push(bankRating({existingBankAddressInChain: _bankAddr,
										  bankAddressToValidate: msg.sender}));
			 return 1;
            }
	    }
	    return 0;                      
	}
    
    /**
     * This method cheks the bank Rating
     */
    function checkBankRating(address _bankAddress) internal view returns (bool){
		
		  for(uint i=0;i<allBankRatings.length;i++){
		  if (allBankRatings[i].bankAddressToValidate == _bankAddress)
			 return true;
		  }
		  return false;
	}
		
    /**
     * This method check is a particular customer has been already voted or not
     */
     
    function checkCustomereRating(address _bankAddr) internal view returns(bool){    
		for (uint i=0;i<allCustomerRatings.length;i++){
				if (allCustomerRatings[i].bankAddress==_bankAddr)
					return true;
		}
		return false;                
	}
	
	/**
     * This method check if a bank is valid or not. 
     */
	function isBankValid(address _bankAddress) internal view returns(bool){
    	for(uint i=0;i<allBanks.length;i++){
    			  if (allBanks[i].ethAddress==_bankAddress && allBanks[i].bankRating > 50 ){
					   return true;
				}
		} 
    	return false;   
	
	}
	
	function doesBankExists() internal view returns(bool){
		for(uint i=0;i<allBanks.length;i++){
			  if (allBanks[i].ethAddress==msg.sender && allBanks[i].bankRating > 50 ){
			     return true;
			  }
		} 
		return false;   
		
		}
	
    /**
     * This method check if the customer is valid or not. 
     */
	function isCustomerValid(string memory customerName) internal view returns(bool){
		for(uint i=0;i<allCustomers.length;i++){
	    	if (stringsEquals(allCustomers[i].userName,customerName)){
		     	return true;
		    }
	    }
	    return false;   
	}
	
	function isKYCAlreadyExists(string memory _custName) internal view returns(bool){
		for(uint i=0;i<allKYCRequests.length;i++){
			  if (stringsEquals(allKYCRequests[i].userName,_custName)){
			   return true;
			  }
		} 
		return false;   
	}

   /**
    * This method returns all kycrequest documents for a particular bank. 
    * When i was returning this method with an array of kycrequeststhe program asked med import experimental package so did it.
    */
    function getAllKYCRequestForABank(address _bankAddress) public  payable returns(KYCRequest[] memory){
		require(isBankValid(_bankAddress),'No Bank exists with this address');
		for(uint i=0;i<allKYCRequests.length;i++){
	   		if (allKYCRequests[i].bank == _bankAddress  ){
	    		return allKYCRequests;
    	  }
		}
	}
	/**
	 * This method returns a particular Bank's Rating
	 */
	function getBankRating(address _bankAddress) public view returns(uint){
		require(isBankValid(_bankAddress),'No Bank exists with this Address');
		for(uint i=0;i<allBanks.length;i++){
			if (allBanks[i].ethAddress==_bankAddress){
				return allBanks[i].bankRating;
			}
		} 
	}	
		
    function getCustomerRating(string memory custName) public view returns(uint){
		require(isCustomerValid(custName),'Not a valid customer');
		for(uint i=0;i<allCustomers.length;i++){
			if (stringsEquals(allCustomers[i].userName,custName)){
				return allCustomers[i].customerRating;
			}
		} 
	}	


// function to compare two string value
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b); 
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

}
