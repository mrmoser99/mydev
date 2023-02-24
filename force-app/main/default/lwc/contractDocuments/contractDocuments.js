import { LightningElement, wire, track} from 'lwc';
import SearchContractDocs from '@salesforce/apex/eArchiveUtils.SearchContractDocs';
import GetDocument from '@salesforce/apex/eArchiveUtils.GetDocument';
import { CurrentPageReference } from 'lightning/navigation'

/* Date       - BUG/PBI    - Author                   - Description
 * 02/12/2022 - PBI 870392 - Lucas Lucena  -          As a portal user I want to access copies of documents at the contract detail level
 * 15/12/2022 - PBI 870392 - Lucas Lucena  -          Added logs for testing and fixed datatable UI controller
 * 06/01/2022 - PBI 870392 - Lucas Lucena  -          Fixed downloaded file view issue
 * 09/02/2022 - PBI 865139 - Dibyendu  -          Add field - Document name +date
*/

const columns = [
    { 
        label: '', 
        type: 'button', 
        disabled: true,
        fixedWidth: 35,
        typeAttributes: {
            iconName: 'utility:page',
            variant: 'base',           
        },
    },
    { 
        label: 'Document Name-Date' , 
        fieldName: 'Name',
        fixedWidth: 300,
        type: 'Text', 
        hideDefaultActions: true, 
    },
    { 
        label: 'DIN' , 
        fieldName: 'din', 
        hideDefaultActions: true
    },
    { 
        label: 'Action', 
        type: 'button',  
        fixedWidth: 80, 
        typeAttributes: {
            iconName: 'utility:download',
            variant: 'base',           
        },
    }
];

const dataEmpty = [];
let mapDinTimestamp;

export default class ContractDocuments extends LightningElement {
    contractId;
    columns = columns;
    record = {};
    tableControl = false;
    @track dataForm = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.contractId = currentPageReference.attributes.recordId;
        }
    }

    @wire(SearchContractDocs, { contractNumber: '$contractId' })
    documentsResponse({ error, data}){ 
        let dataFormAux = []; 
        let mapDinTimestampAux = new Map(); 
        if(data){
            console.log('contractId: ', this.contractId);
            data = JSON.parse(data);
            console.log('SearchContractDocs parsed result: ', data);
            for (let i = 0; i < data.length; i++) {
                for (let j = 0; j < data[i].indexValues.indexValue.length; j++){
                    if(data[i].indexValues.indexValue[j].name == 'Document Name'){  
                        dataFormAux.push({'Name' : data[i].indexValues.indexValue[j].value + '-'+ data[i].indexValues.indexValue[j+4].value, 'din' : data[i].din});
                        mapDinTimestampAux.set(data[i].din, data[i].timeStamp);
                    }  
                }
            }
            this.mapDinTimestamp = mapDinTimestampAux;
            console.log('Datatable builder: ', dataFormAux);
            if(dataFormAux.length > 0){
                this.tableControl = true;
                console.log('tableControl change: ', this.tableControl);
            }
            this.refreshDataForm(dataFormAux);
        }else if(error){
            console.log('documentsResponse error: ', error);
        }
    };

    refreshDataForm(dataFormAux){
        this.dataForm = dataFormAux;
    }

    downloadFile(event){
        const row = event.detail.row;
        this.record = row;
        console.log('DIN: ', this.record.din);
        console.log('DIN Timestamp: ', this.mapDinTimestamp.get(this.record.din));
        GetDocument({ dinNumber: JSON.stringify(this.record.din), timeStamp: this.mapDinTimestamp.get(this.record.din)})
            .then((result) => {
                result = JSON.parse(result);
                console.log('GetDocument parsed result:', result);
                this.createFile(result.documentData.binaryData, result.contentType, this.record.Name);
            })
            .catch((error) => {
                console.log('Download error: ', error);
            });
    }

    createFile(binaryDataAux, dataExtensionAux, dataNameAux){
        
        var downloadBlob = (function () {
            let element = document.createElement('a');
            element.setAttribute('href', 'data:' + dataExtensionAux + ';base64,' + binaryDataAux);
            element.setAttribute('download', dataNameAux);
            element.style.display = 'none';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
            
        }());
            
        downloadBlob([binaryDataAux], dataExtensionAux, dataNameAux);
   
    }

}