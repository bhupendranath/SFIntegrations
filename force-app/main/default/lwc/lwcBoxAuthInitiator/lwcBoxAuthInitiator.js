import { LightningElement } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import getAuthStatus from '@salesforce/apex/LWCBoxAuthController.getAuthStatus';
import fetchFilesFromFolder from '@salesforce/apex/LWCBoxAuthController.fetchFilesFromFolder';
import getFiles from '@salesforce/apex/LWCBoxAuthController.getFilesFromFolder';

export default class LwcBoxAuthInitiator extends NavigationMixin(LightningElement) {


    authStatus = "Not Authenticated";
    filesList   ;

    connectedCallback(){
        //1.Grab the url from the Address bar
        const url = window.location.href;

        //2.I need to convert the String to URL instance : <<URL(url)>>
        //3.Strip the value of the key i.e c__code
        const code = new URL(url).searchParams.get("c__code"); //2 & 3 points of the above code in one line
        //4.Make the Subsequent callout to get the access token (there are many was to get access token but, here we will use 'apex method' to get token)
        getAuthStatus({authCode: code})
        .then((response) => {console.log(response);
            this.authStatus = JSON.stringify(response);
        })
        .catch((error) => {console.log(error);
            this.authStatus = error;
        });
    }

    handleAuthenticate(){

        //But this lwc page reference will always open in "new tab", which will cause an error(Invalid grant exception) on getting access token. 
        // Hence we will have to use Vanilla JS to use NavigationMixin
        /*let pageReference = {
            type: 'standard__webPage',
            attributes: {
                url: 'https://account.box.com/api/oauth2/authorize?client_id=ncbwurnanxb183gjkl795225lx8ujzc4&response_type=code'
            }

        };*/

        //Vanilla JS(Pure JS wthout using external libraries or framework)
        //Vanilla JS (Here it will open page in same tab not new tab (Issue).)
        window.location.href = 'https://account.box.com/api/oauth2/authorize?client_id=ncbwurnanxb183gjkl795225lx8ujzc4&response_type=code';

        this[NavigationMixin.Navigate](pageReference);

    }

    handleFetchFiles(){
        //we are making imperative call here for apex method
        fetchFilesFromFolder()
        .then((response) => {console.log(response);
           // this.filesList = JSON.stringify(response);
            //here we are trying to chain promises
            //Because after http callout DML is fine [Ex: We are updating custom setting in refreshAccessToken() method]
            //but we can not make callout once DML operation is done 
            //Hence, chaining promises to make callout after DML is fine
            return getFiles();
        })
        .then((response)=>{console.log(response);
        this.filesList = JSON.stringify(response);
        })
        .catch((error) => {console.log(error);});
    }
}