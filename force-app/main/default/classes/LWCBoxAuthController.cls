public with sharing class LWCBoxAuthController {    
    
    @AuraEnabled
    public static String getAuthStatus(String authCode){

        //getting client and client secret from Custom Metadata
        Box_Credential__mdt boxCredsMetadata = Box_Credential__mdt.getInstance('Box_Dev_inst_Creds');

        String ClientId = boxCredsMetadata.Client_Id__c;
        String ClientSecret = boxCredsMetadata.Client_Secret__c;
        
        //Step1- instantiate http class
        Http http = new Http();
        
        //Step2- instantiate httpRequest class and frame the request
        HttpRequest request = new HttpRequest();
        request.setHeader('Accept','application/json');
        //End Point Name in Box.com << Request access token >>
        request.setEndpoint('https://api.box.com/oauth2/token');//We can store endpoint in Apexclass/NameCredential/Even Hardcode it
        request.setMethod('POST'); //if method is post then we "cannot append" endpoints rather we will use: setBody(keys)
        //we can store client id and client secret in Apexclass/CustomSetting/Even CustomLable(not recommended)
        request.setBody('grant_type=authorization_code&code='+authCode+'&client_id='+ClientId+'&client_secret='+ClientSecret);
        
        //Step3- recieve/handle the reponse
        
            HttpResponse response = http.send(request);
            String body = response.getBody();

            //1.Let Me parse the response (using JSON.deserilizeUntyped() method)
            //here in [JSON response] key will always be (String) but value can be String, Integer or other node, hence we have to use (Object) as a type : Map<String, Object>()
            Map<String, Object> parseAuthResponse = (Map<String, Object>)JSON.deserializeUntyped(body);
            //2.Extract the AToken, RToken, Expires In
            String accessToken= (String)parseAuthResponse.get('access_token');
            String refreshToken= (String)parseAuthResponse.get('refresh_token');
            Integer expiresIn= (Integer)parseAuthResponse.get('expires_in');

            //3.Store it in BoxCredStore__c custom setting[temporary store] OR insert record in custom setting: BoxCredStore__c
            insert new BoxCredStore__c(setupOwnerId=UserInfo.getUserId(), Access_Token__c=accessToken, Refresh_Token__c=refreshToken, Expires_in__c=expiresIn);
            
            System.debug('Response : '+response);

            if(response.getStatusCode() == 200){
                return 'Successfully Authenticated';
            }
            return 'Auth failed';
    }

    
    @AuraEnabled
    public static String fetchFilesFromFolder(){

        Boolean isAccessTokenValid = validateAccessToken();

        String filesList;
        if(isAccessTokenValid){

            //calling below method to get files
            filesList = getFilesFromFolder();
            return filesList;
        }
        else{
            //Calling refresh token method to update Access Token and refresh Token n Custom Setting
            refreshAccessToken();

            //after getting refresh access token now we can get files by calling below method
            //filesList = getAllFilesFromFolder(credStore);

            //here we can will after getting we cannot make callout in the same transaction 
            //hence we have to use async method to make callout but we will use Javascript Asunc method not Apex async method to get files
            //Now in JS we will use promises to implement this
        }

        //system.debug('files list----------'+filesList);
        return null;
    }

    @AuraEnabled
    public static Boolean validateAccessToken(){

        //BoxCredStore__c credStore = [SELECT Access_Token__c from BoxCredStore__c WHERE SetupOwnerId =: UserInfo.getUserId() LIMIT 1];
        
        //another way of querying custom setting
        //BoxCredStore__c credStore = BoxCredStore__c.getValues(Userinfo.GetUserId());
        BoxCredStore__c credStore = getBoxCredStore();

        DateTime lastUpdated = credStore.LastModifiedDate;
        DateTime currentTime = DateTime.Now();

        //Calculating time different
        long timeDelta = currentTime.getTime() - lastUpdated.getTime();
        //delta has to be converted to minutes
        //for box.com usually Expires_in__c is 60 minutes
        long deltaInMinutes = timeDelta / (1000*60);

        //checking the delta in minutes
        if(deltaInMinutes > credStore.Expires_in__c){
            return false;
        }else{           
            return true;
        }

    }

    @AuraEnabled
    public static void refreshAccessToken(){

        //getting client and client secret from Custom Metadata
        Box_Credential__mdt boxCredsMetadata = Box_Credential__mdt.getInstance('Box_Dev_inst_Creds');

        String ClientId = boxCredsMetadata.Client_Id__c;
        String ClientSecret = boxCredsMetadata.Client_Secret__c;

        //BoxCredStore__c credStore = BoxCredStore__c.getValues(Userinfo.GetUserId());
        BoxCredStore__c credStore = getBoxCredStore();
        
         //Step1- instantiate http class
        Http http = new Http();
        
        //Step2- instantiate httpRequest class and frame the request
        HttpRequest request = new HttpRequest();
        request.setHeader('Accept','application/json');
        //End Point Name in Box.com << Request access token >>
        request.setEndpoint('https://api.box.com/oauth2/token');//We can store endpoint in Apexclass/NameCredential/Even Hardcode it
        request.setMethod('POST'); //if method is post then we "cannot append" endpoints rather we will use: setBody(keys)
        //we can store client id and client secret in Apexclass/CustomSetting/Even CustomLable(not recommended)
        request.setBody('grant_type=refresh_token&refresh_token='+credStore.Refresh_Token__c+'&client_id='+ClientId+'&client_secret='+ClientSecret);
        
        //Step3- recieve/handle the reponse
        
            HttpResponse response = http.send(request);
            //String body = response.getBody();

        //Now we need to update Custom Setting by getting fresh access token and refresh token
        if(response.getStatusCode() == 200){

            //parsing the response using JSON.deserializeUntyped() method
            Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            String newAccessToken = (String)responseBody.get('access_token');
            String newRefreshToken = (String)responseBody.get('refresh_token');

            //After getting new Access token we will now assign it to Custome setting and will update it
            credStore.Access_Token__c = newAccessToken;
            credStore.Refresh_Token__c = newRefreshToken;

            update credStore;
        }

    }

    @AuraEnabled
    public static String getFilesFromFolder(){

        //BoxCredStore__c credStore = BoxCredStore__c.getValues(Userinfo.GetUserId());
        BoxCredStore__c credStore = getBoxCredStore();

        Http http = new Http();
            
        HttpRequest req = new HttpRequest();
        req.setHeader('Accept','application/json');
        //req.setEndpoint('https://api.box.com/2.0/folders/:folder_id/items');//here we need to provide folderId which we can get from box.com
        //End Point Name in Box.com << List items in folder >>
        req.setEndpoint('https://api.box.com/2.0/folders/310461657104/items');
        req.setMethod('GET');
        //We can check from Postman that header prefix is "Bearer"
        //here after Bearer we have to add 1 space and then token
        req.setHeader('Authorization','Bearer '+credStore.Access_Token__c);

        HttpResponse res = http.send(req); //this response will retrieve list of folder items
        return res.getBody();

    }

    @AuraEnabled
    public static BoxCredStore__c getBoxCredStore(){

        BoxCredStore__c credStore = BoxCredStore__c.getValues(Userinfo.GetUserId());
        return credStore;
    }


}