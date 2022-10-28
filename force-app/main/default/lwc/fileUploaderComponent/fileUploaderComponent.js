import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/FileUploader.uploadFile'
export default class FileUploaderCompLwc extends LightningElement {
    @api recordId;
    fileData;
    @api isLoading = false;
    filesUploaded = [];
    fileDataList = [];  
    fileName = ''; 
    MAX_FILE_SIZE = 10485760; //10mb
    //MAX_FILE_SIZE = 1024; //10mb

    
    handleFilesChange(event) {   

        this.isLoading = true;

        console.log(event.target.files);
         
        if(event.target.files.length > 0) {
            
            this.fileDataList = [];
            
             
             
            this.filesUploaded = event.target.files;

          
            
            //looping in all the files
            for(let i=0;i<event.target.files.length;i++){
                
                let fileCon = this.filesUploaded[i];    

                //chek uploaded file type
                let freader = new FileReader();  //we use browser FileReader API to generate the data stream.
             
                freader.onload = () => {
                    let base64 = freader.result.split(',')[1];
                    
                    this.fileData = {
                        'filename': fileCon.name,
                        'base64': base64,
                        'recordId': this.recordId
                    }   

                    console.log('yo yo ' + this.fileData.filename);
                     
                    
                    if (
                        this.fileData.filename.includes('.docx')
                    || this.fileData.filename.includes('.doc')
                    || this.fileData.filename.includes('.pdf')
                    || this.fileData.filename.includes('.xls')
                    || this.fileData.filename.includes('.xlsx')
                    || this.fileData.filename.includes('.jpeg')
                    || this.fileData.filename.includes('.jpg')
                    ){
                     
                     
                        const isFileSizeExceeded = this.checkFileSize(fileCon);     
                
                        if(isFileSizeExceeded){
                            const evt = new ShowToastEvent({
                                title: 'Error',
                                message: 'File size limit (10MB) has been exceeded!',
                                variant: 'error',
                                duration:5000,
                            });
                            this.dispatchEvent(evt);
                            this.isLoading = false;
                            return;
                        }
                    }
                         
                    else{
                            console.log('here3');
                        const evt = new ShowToastEvent({
                        title: 'Error',
                            message: 'Only pdf, jpeg, doc, docx, xls and xlsx files can be uploaded!',
                            variant: 'error',
                            duration:5000,
                        });
                        this.dispatchEvent(evt);
                        this.isLoading = false;
                        return;
                    }

                    this.fileDataList.push(this.fileData);   
                     
                    if( this.fileDataList.length == this.filesUploaded.length){
                        this.isLoading = true;
                        this.doUploads();
                        
                        this.isLoading = false;
                        
                    }
                };
             
                freader.readAsDataURL(fileCon);   
                   
            }   
             
            
            
            this.fileName = this.fileName.slice(0, -1); //the file names   
             
             
        }
    }
    checkFileSize(fileCon){
        if (fileCon.size > this.MAX_FILE_SIZE) {                    
            return true;
        }
    }
    
    doUploads(){
        
        for(let i=0;i<this.fileDataList.length;i++){
            const {base64, filename, recordId} = this.fileDataList[i];
            uploadFile({ base64, filename, recordId }).then(result=>{
                    console.log('result of upload is: ' + result) ;
                    this.fileData = null;
                
                    const selectedEvent = new CustomEvent("refreshlist", {
                            detail: 'hello'
                    });
                    // Dispatches the event.
                    this.dispatchEvent(selectedEvent);
                    this.isLoading = false;
                    
            });

        }

        let title = 'File Upload Successful!';

        this.toast(title);

        this.fileDataList = [];
        this.filesUploaded = [];
        

    }
    

    toast(title){

        
        
        
     
        const toastEvent = new ShowToastEvent({
            title: 'Success', 
            variant:"success",
            message: 'The file upload was successful!'
           
        })
        this.dispatchEvent(toastEvent);

        

        
    }
}