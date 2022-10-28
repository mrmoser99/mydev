import { LightningElement, api,track } from 'lwc';
import uploadFile from '@salesforce/apex/ESignInformationController.uploadFileinReviewScreen'
import { reduceErrors,constants } from 'c/ldsUtils';
export default class LightningFileUpload extends LightningElement {
    
    labels = constants;
    @api recordId;
    @api indexRow;

    @track fileName = ''; 
    @track fileDataList = [];  
    @track message = {};   
    @track filesUploaded = [];
    
    @track isLoading = false;
    fileData;
    MAX_FILE_SIZE = 10485760 ; //10mb

    /**To hold the files uploaded by the user in the screen */
    handleFilesChange(event) {   
        
        if(event.target.files.length > 0) {
            this.isLoading = true;
            this.filesUploaded = event.target.files;
            //looping in all the files
            for(let i=0;i<event.target.files.length;i++){
                let fileCon = this.filesUploaded[i];    
                //chek uploaded file type
                const isFileTypeInvalid = this.checkFileType(event.target.files[i].type);
                if(isFileTypeInvalid){
                    this.isLoading = false;
                    this.message = {
                        messageStr : this.labels.File_type_error,
                        type : 'error'
                    }
                    this.handleDispatchEvent('dispatchmsg',this.message);                 
                    return;
                }
                //chek file size if greater than the allowed size                              
                const isFileSizeExceeded = this.checkFileSize(fileCon);     
                if(isFileSizeExceeded){
                    this.isLoading = false; 
                    this.message = {
                        messageStr : this.File_size_cannot_exceed+' '+this.formatBytes(this.MAX_FILE_SIZE, 2) +'.\n' + this.labels.Selected_file_size + ' ' + this.formatBytes(fileCon.size, 2),
                        type : 'error'
                    }
                    this.handleDispatchEvent('dispatchmsg',this.message);
                    return;
                }
                
                this.fileName = this.fileName + this.truncateText(fileCon.name,5) + ', ';    
                let freader = new FileReader();  //we use browser FileReader API to generate the data stream.
                freader.onload = () => {
                    let base64 = freader.result.split(',')[1];
                    this.fileData = {
                        'filename': fileCon.name,
                        'base64': base64,
                        'indexRow': this.indexRow
                    }                   
                    this.fileDataList.push(this.fileData);                 
                };
                freader.readAsDataURL(fileCon);               
            }      
            this.fileName = this.fileName.slice(0, -1); //the file names   
            this.isLoading = false;
        }
    }

    /**Handle the logic on click of the submit button
     * Disptach an event to the parent cmp.
     */
    handleSubmitClick(){
        
        if(Array.isArray(this.fileDataList) && this.fileDataList.length){
            this.isLoading = true;
            this.handleDispatchEvent('senddocuments',this.fileDataList); //fire an event to parent cmp
        }else{
            this.message = {
                messageStr : this.labels.Please_upload_a_document,
                type : 'error'
            }
            this.handleDispatchEvent('dispatchmsg',this.message);
        }      
    }

    /**Sends the documents to DCV by apex call out */
    @api 
    sendDocstoDCV(docsList){
    
        const rowId = docsList['uid'];
        if(rowId != this.indexRow){
            return;
        }
        uploadFile({  //callout to apex
            docsStr : JSON.stringify(docsList)
        }).then(result => {                     
          
            if(result == 200){             
                this.message = {
                    messageStr : this.labels.Documents_send_succesfully,
                    type : 'success'
                }
                this.handleDispatchEvent('dispatchmsg',this.message);   
                this.fileName = ''; //clear out the file name in UI
                this.fileDataList = [];   //clear out the file list in UI   
                this.isLoading = false;                
            }else{       
                this.isLoading = false;     
                this.message = {
                    messageStr : this.labels.Contact_Admin_Error, //generic msg
                    type : 'error'
                }
                this.handleDispatchEvent('dispatchmsg',this.message);   
            }
                
        }).catch(error => {
            this.isLoading = false;        
        });
    }

    //function to return a shortened string with ellipsis if it's too long.
    truncateText(text,limit){
       return text && text.length <= limit ? text : text.slice(0,limit) +'...pdf';
    }

    /*allow only pdf
    *update the custom label with semi-colon(;) for more file formats. Ex: application/pdf;image/jpeg
    */
    checkFileType(fileType){      
        let allowedFiles = this.labels.Allowed_file_format; 
        const allowedFileFormats = allowedFiles.split(';');
        if(!allowedFileFormats.includes(fileType)){         
            return  true;  
        }
    }

    //allow files within the max size
    checkFileSize(fileCon){
        if (fileCon.size > this.MAX_FILE_SIZE) {                    
            return true;
        }
    }

    /**Generic function to dispatch events from child-to-parent */
    handleDispatchEvent(eventName,eventDetails){
        const selectEvent = new CustomEvent(eventName, {
            detail: eventDetails
        });
        this.dispatchEvent(selectEvent);
    }
    
    /**format the bytes to MB */
    formatBytes(bytes,decimals) {
        if(bytes == 0) return '0 Bytes';
        let k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
}