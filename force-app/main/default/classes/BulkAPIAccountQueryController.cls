public class BulkAPIAccountQueryController {
    
    public String[] accountLine = new String[]{}; //it will have individual records
    
    //We will push wrapper class details into List
    public List<AccountWrapper> accountListWrapper{set;get;}
    
    String locator = '';  //in the first time, locator will be null
    public void fetchRecords(){
         
        //1. Create a Bulk Query job using Bulk API
        //Bulk API Job: '/services/data/v62.0/jobs/query/750J1000008a3kLIAQ/results?maxRecords=5'
         String endPoint = URL.getOrgDomainUrl().toExternalForm(); //Add this baseUrl to Remote Site Seting
        
        endPoint += '/services/data/v62.0/jobs/query/750J1000008a3kLIAQ/results?maxRecords=5';
        if(locator != ''){
            endPoint += '&locator='+ locator;
        }
                
        //2. Make a REST callout to the endpoint
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            //add space after 'bearer ' else we'll get error: INVALID_AUTH_HEADER
            req.setHeader('Authorization','Bearer '+UserInfo.getSessionId()); 
            req.setMethod('GET');
            req.SetEndpoint(endPoint);
            HttpResponse res = http.send(req);
            System.debug('Result: '+res.getBody()); //we will get the CSV result so we don't have to beautify it
        
            //From response header getting: sforce-locator: MTA6MEdhSjEwMDAwMDZUdW1RS0FTOjA [to fetch next set of records]
            locator = res.getHeader('Sforce-Locator');  //make sure it is capitalize <<Sforce-Locator>>
        
            String body = res.getBody();
            accountLine = body.split('\n'); //adding new line after each record
        
        
        //Instanciating wrapper class list
        accountListWrapper  = new List<AccountWrapper>();
            //result is CSV type and at 0 index has record Name,Id,Rating etc infor will be there 
            //hence we will start iteration from 1
        for(integer i=1;i<accountLine.size();i++){
            String[] csvAccountRecord = accountLine[i].split(','); //spliting each CSV record after comma: ,
            accountListWrapper.add(new AccountWrapper(csvAccountRecord[0].replace('"',''),csvAccountRecord[1].replace('"',''),csvAccountRecord[2].replace('"',''),csvAccountRecord[3].replace('"','')));
        }
        //3. Process the response and display the result back to the users
    }
    
    //Creating wrapper class to push CSV record details
    public Class AccountWrapper{
        public String Id{set;get;}
        public String Name{set;get;}
        public String Industry{set;get;}
        public String Rating{set;get;}
        
        public AccountWrapper(String cId,String cName,String cInustry,String cRating){
            this.Id = cId;
            this.Name = cName;
            this.Industry = cInustry;
            this.Rating = cRating;
        }
    }
}