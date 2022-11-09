import { LightningElement, wire, api, track } from 'lwc';
//import getAccountTest from '@salesforce/apex/ContractDocumentsService.getAccountTest';

const columns = [
    { 
        label: '', 
        type: 'button', 
        fixedWidth: 35,
        typeAttributes: {
            iconName: 'utility:page',
            variant: 'base',           
        },
    },
    { 
        label: 'Name' , 
        fieldName: 'Name',
        type: 'Text', 
        hideDefaultActions: true, 
    },
    { 
        label: 'DIN' , 
        fieldName: 'BillingStreet', 
        hideDefaultActions: true
    },
    { 
        label: 'Action', 
        type: 'button', 
        typeAttributes: {
            iconName: 'utility:download',
            variant: 'base',           
        },
    }
];

const dataEmpty = [];


export default class ContractDocuments extends LightningElement {
    columns = columns;
    dataPlaceHolder = [
        {Name: 'Doc1', BillingStreet: 'DMI234-23SDF4-I234O-O52H5' },
        {Name: 'Doc2', BillingStreet: 'DMI234-23SDF4-I234O-O52H5' },
        {Name: 'Doc3', BillingStreet: 'DMI234-23SDF4-I234O-O52H5' }
    ];

    filesToShow = true;
    filesList = [
        { 
            label: 'teste1' , 
            url: 'teste1', 
            value: 'teste1'
        },
        { 
            label: 'teste2' , 
            url: 'teste2', 
            value: 'teste2'
        },
        { 
            label: 'teste3' , 
            url: 'teste3', 
            value: 'teste3'
        }
    ];

    //@wire(getAccountTest)
    //accounts;

    /*@wire(getAccountTest)
    getAccounts({ error, data }){
        if(error){
            console.log('Contract Document Error: ', error);
        }else{
            console.log('Contract Document Data: ', data);    
        }
    }*/

}