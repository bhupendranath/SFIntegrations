@RestResource(urlMapping='/Account/Contacts/*')
global with sharing class ExploreRestAccountController {

    //Endpoint (Base URL + URI)
    //https://instance.salesforce.com/services/apexrest/Account/Contacts/*
    //Account Id: https://instance.salesforce.com/services/apexrest/Account/Contacts/001XXXXXXX 
    //We need to get this Account ID and add into our Query
    
    
    //Whenever get request is made to this endpoint by external system then below httpget method is invoked
    @HttpGet
    global static Account doGet(){
        //RestContext.request : RestContext Class is using request method, which will give the 
        //request details(Including Endpoint) which is send by external system via Postman/Node.jsApp/PHPApp
        RestRequest req = RestContext.request;
        
        //Understanding RestContext class
        System.debug('Request Params: '+req.params);
        System.debug('Request uri: '+req.requestURI);
        System.debug('Resource Path or Controller urlMaping: '+req.resourcePath);
        //requestURI : it will return request URI = 'Account/Contacts/001XXXXXXX' 
        //but we are interested in substring( and we want substring of last Index)
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        return [SELECT Id, Name, (Select Id, Name FROM Contacts) FROM Account Where Id =:accountId];
    }
    
    /*
     * Premitive Data Tyeps
    @HttpPost
    global Static Account doPost(String Name, String Industry, String Rating){
        Account a = new Account(); //Instanciating Acc
        a.Name = Name; //Mapping fields
        a.Industry = Industry;
        a.Rating = Rating;
        
        insert a;
        return a;
    } */
    
    
    //Simple params in POST Method
    //When 3rd party developer want to send data in the form of JSON then we will have to use 
    //sObject type as parameter and this JSON should be deserialize into type sObject
    /*
     * 
    @HttpPost
    global Static Account doPost(){
        
        RestRequest req = RestContext.request; 
        String s = 	req.requestBody.toString();  //requestbody is in BLOB format, we need to convert it into string
        
        //now we will deserialise it into sObject
        Account a= (Account)JSON.deserialize(s, Account.class);
            
        insert a;
        return a;
    }*/
    
    //wrapper class for Complex params in POST Method
    global class RequestWrapper{
         Account account; //this account&contacts value has to be same on Postman request as well
         Contact[] contacts;
    }
    
    //Complex params in POST Method
    //here deserialization will be automatically handled by the SF framework
    @HttpPost
    global Static Account doPost1(RequestWrapper request){
        
        insert request.account;  //this request value has to be same on Postman request as well
        insert request.contacts;
        return request.account;
    }
    
    //return response from POST method using RestContext
    //When to Use: When We want modify JSON response and want to add more key or more information  
    //Test in Postman with same JSON request body as previous implementation
    /*
     * 
    @HttpPost
    global Static void doPost2(RequestWrapper request){
        
        //RestResponse : as per documentation resonse Body will be BLOB
        RestResponse res = RestContext.response;
        Account a = request.account;
        insert a;
        Contact[] c = request.contacts;
        insert c;
        
        if(a!=null && c!=null){
            res.statusCode = 200;
            //here, JSON.serialize(a) => will convert object into String 
            //then we are converting string into BLOB
            res.responseBody = BLOB.valueOf(JSON.serialize(a));            
        }else{
            res.statusCode = 500;
            res.responseBody = BLOB.valueOf('Something Went Wrong');
        }
    } */
    
    
    //
    @HttpDelete
    global static void doDelete(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        
        //If Account has child record then it throws error to delete child records first
        //Delete Case
        delete [SELECT Id from Case Where AccountId =:accountId];
        
        //Delete Opportunity
        delete [SELECT Id from Opportunity Where AccountId =:accountId];
        
        //Delete Contact
        delete [SELECT Id from Contact Where AccountId =:accountId];
        
        //Delete the Account
        delete [SELECT Id from Account where Id =:accountId];
        
        res.statusCode = 200;
        res.responseBody = BLOB.valueOf(accountId+' got deleted');
    }
    
}