public class ClientCredsController {
    
    public String body {set;get;}
    public void authenticate(){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.box.com/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Accept','application/json');
        //box_subject_type=user&box_subject_id=40597259992 : we can get this detaild from App's 'General setting' in Box.com
        req.setBody('client_id=ncbwurnanxb183gjkl795225lx8ujzc4&client_secret=OZyYnsuPOGxRTSB78rbBXchRTav9bpmY&grant_type=client_gredential&box_subject_type=user&box_subject_id=40597259992');
        
        HttpResponse res = http.send(req);
        
        //body = res.getBody();
        
        fromJSON d =(fromJSON)JSON.deserialize(res.getBody(),fromJSON.class);
        
        body = fetch_files(d.access_token);
    }
    
    public String fetch_files(String access_token){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.SetHeader('accept','application/json');
        req.setEndpoint('https://api.box.com/2.0/folders/310461657104/items');
        req.setMethod('GET');
        req.setHeader('Authorization','Bearer '+access_token);
        
        HttpResponse res = http.send(req);
        
        return res.getBody();
        
    }
    
    public class fromJSON{
	public String access_token;	//gBrTshXlJbva59GacTPWDKc0Wmi357Fg
	public Integer expires_in;	//4011
	public cls_restricted_to[] restricted_to;
	public String token_type;	//bearer
	
    }
    
    class cls_restricted_to {
	}
    

}