import { LightningElement,api,track } from 'lwc';
import getChecklistQuestion from '@salesforce/apex/ESignInformationController.getChecklistQuestion';
import {reduceErrors,showPopUpNotification} from 'c/ldsUtils';

export default class ReviewScreenCmp extends LightningElement {

    @track checklistQuestions = [];
    _quoteId = '';
    isLoading = false;   

    @api
    get quoteId() {
        return this._quoteId;
    }

    set quoteId(value) {    
        this._quoteId = value;      
        this.checklistQuestions = [];
        this.getChecklistQuestion();
    }

    //to show message in popup Notification component
    handleMessageFromUploadCmp(event){
        showPopUpNotification(this, event.detail.messageStr, event.detail.type);
    }

    /**To call the child comp to send the file details for sending */
    handleSendDoc(event){       
        let rowDetails = this.checklistQuestions[parseInt(event.detail[0].indexRow)]; //getting the questionaire row details
        rowDetails['uploadDocList'] = event.detail; //adding the uploaded doc array     
        this.template.querySelectorAll('c-lightning-file-upload').forEach(element => {
           element.sendDocstoDCV(rowDetails);
        });
    }

    /**
     * retrive the checklist question and show on the Review screen
     */
    getChecklistQuestion(){
        
        getChecklistQuestion({  //apex callout
            quoteId : this._quoteId
        }).then(result => {                    
           for(let eachRec in result){                
                if(result[eachRec]['response'] != 'N/A'){                  
                    const newRecObj = {
                        'uid' : this.checklistQuestions.length,
                        'questionName' : result[eachRec]['questionName'],
                        'response' : result[eachRec]['response'],
                        'comment' : result[eachRec]['comment'],
                        'checked' : result[eachRec]['response'] == 'Yes' ? true : false,
                        'className' : result[eachRec]['response'] == 'Yes' ? 'greenCheckbox' : result[eachRec]['response'] == 'No' ? 'redCheckbox' : '',
                        'color' : result[eachRec]['response'] == 'Yes' ? 'color:#009A00' : result[eachRec]['response'] == 'No' ? 'color:#9A151C' :  result[eachRec]['response'] == 'N/A' ? 'color:#999999' : 'color:#FDD13A', //color code taken from zero-heigt
                        'reasonCode' : result[eachRec]['reasonCode'],
                        'docType' : result[eachRec]['docType'],
                        'showUploadBtn' : result[eachRec]['docType'] && result[eachRec]['response'] == 'No' ? true : false,
                        'dealName' : result[eachRec]['dealName'] 
                    };
                    this.checklistQuestions.push(newRecObj);                  
                }          
            }     
        })
        .catch(error => {});
    }    
}