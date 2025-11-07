/**
 * Class : BoxAuthController
 * @auther Bhupendra
 * Last Modified By :
 * Last Modified Date :
 * Auth type: PKCE (Proof Key for Code Exchange)
 * Details: BoxAuthPKCEFlowController to make callout and retrieve the JSON detail from Box.com
 * And parsing the JSON responses using JSON.deserializeUntyped() method
 */

public class BoxAuthPKCEFlowController {
    
    public PageReference Authenticate(){
        
        //in PKCE we append endpoint with code_challenge and code_challenge_method
        String endPoint = 'https://account.box.com/api/oauth2/authorize/?client_id=xfoi7i5jz01hfay1nac97sv5zdvmkrq2&response_type=code&code_challenge_method=S256&code_challenge=';
        
        //1. Create Code verifier 
        //(It can be series of chars from: 43-128 chars)
        String codeVerifier = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        
        //2. Encrypt the Code verifier 
        //(here we will use generateDigest(algorithmName,input) method from Crypto class) and it's return will be Blob
        Blob codeVerifierBlob = Blob.valueOf(codeVerifier);   //converting string >> Blob type
        Blob cryptoDigest = Crypto.generateDigest('SHA3-256', codeVerifierBlob);
            
        //3. Encode the code verifier
        //(here we will use base64Encode(inputBlob) method from EncodingUtil class)
        String afterCryptoDigest = EncodingUtil.base64Encode(cryptoDigest);
        
        endPoint = endPoint + afterCryptoDigest;
        
        return new PageReference(endPoint);
    }
    
    public void getAccessToken(){
        
        String authCode = apexpages.CurrentPage().getParameters().get('code');
        String clientId = 'xfoi7i5jz01hfay1nac97sv5zdvmkrq2';
        String clientSecret = 'rSlOn69k1e7jvwtY2RwCDUcS5r2mzpvB';
        String codeVerifier = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String redirectURI = 'https://sfdevcom13-dev-ed--c.develop.vf.force.com/apex/BoxAuthPKCEFlowSuccess';
            
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setHeader('Accept','application/json');
        request.setEndpoint('https://api.box.com/oauth2/token');
        request.setMethod('POST');
        
        //As per best practice if any code has some special chars like: .-*_/&% then we need to encode it by using: <<EncodingUtil.urlEncode('Code','UTF-8')>>
        //Ex. check from anonymous window => system.debug('Encoded url: '+ EncodingUtil.urlEncode('https://sfdevcom13-dev-ed--c.develop.vf.force.com/apex/BoxAuthPKCEFlowSuccess','UTF-8'));
        String body = 'grant_type=authorization_code'+
            '&code='+ EncodingUtil.urlEncode(authCode,'UTF-8') +
            '&client_id='+ EncodingUtil.urlEncode(clientId,'UTF-8')  +
            '&client_secret='+ EncodingUtil.urlEncode(clientSecret,'UTF-8') +
            '&redirect_uri='+ EncodingUtil.urlEncode(redirectURI,'UTF-8') +
            '&code_verifier='+ EncodingUtil.urlEncode(codeVerifier,'UTF-8');
        
        request.setBody(body);
        //now we can also tell the server that we have encoded the URL
        request.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        HttpResponse res = http.send(request);
        
        if(res.getStatusCode() == 200){
            system.debug('Access Token: '+res.getBody());
            Map<String,Object> tokenResponse =(Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            String accessToken = (string)tokenResponse.get('access_token');
            
            String filesList = getFilesFromFolder(accessToken);
            
            system.debug('Files list: '+filesList);
        }else{
            system.debug('Auth Failed '+res.getBody());
        }
    }
    
    public String getFilesFromFolder(String accessToken){
        
        Http http = new Http();
        
        Httprequest req = new Httprequest();
        req.setEndpoint('https://api.box.com/2.0/folders/310461657104/items');
        req.setMethod('GET');
        req.setHeader('Accept','application/json');
        req.setHeader('Authorization','Bearer '+accessToken);
        
        HttpResponse res = http.send(req);
        system.debug('inside getFilesFromFolder meth : '+ res.getBody());
        
        return res.getBody();
    }
}