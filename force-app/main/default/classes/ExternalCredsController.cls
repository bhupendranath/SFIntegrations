public class ExternalCredsController {

    public void fetchFileFromFolder(){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        //req.setEndpoint('callout:files_list'); //for hardcoded single folder endpoint Named Cred.: https://api.box.com/2.0/folders/310461657104/items
        //req.setEndpoint('callout:files_list'+'/310461657104/items'); //<Dynamic Endpoint> where Named Cred: https://api.box.com/2.0/folders
        
        //We can make more sophisticated 
        //String.format()=> it takes 2 parameter [1st String with placeholder] and [2nd Value that we need to substitute in the placeholder]
        String endpoint = String.format('callout:files_list/{0}/items',new List<String>{'310461657104'});
        
        //for multiple folder item
        //String endpoint = String.format('callout:files_list/{0}/items/{1}/{2}',new List<String>{'310461657104','abc','xyz'});
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        //Below line is not required it handled by salesforce automatically when we configure external credential
        //req.setHeader('Authorization','Bearer'+access_token);
        
        HttpResponse res = http.send(req);
        //res.getBody();
            
        System.debug('Box.com Files list: '+res.getBody());
    }
    
    //Test this class in Anonymous window
    // ExternalCredsController files = new ExternalCredsController();
    // files.fetchFileFromFolder();
}