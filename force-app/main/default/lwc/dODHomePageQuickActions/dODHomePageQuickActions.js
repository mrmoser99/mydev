/*****************************************
 * PBI:741988
 * Geetha created on 10/6/2022 DLL on Demand
 */

import { LightningElement , track, api} from 'lwc';
import CREATE_QUOTE_ACTION from '@salesforce/resourceUrl/createQuoteAction';
import VIEW_APPLICATION_ACTION from '@salesforce/resourceUrl/ViewApplicationsAction';
import SUBMIT_CREDIT_ACTION from '@salesforce/resourceUrl/SubmitCreditAction';
import VIEW_PORTFOLIO_ACTION from '@salesforce/resourceUrl/ViewPortfolioAction';

export default class DODHomePageQuickActions extends LightningElement {
    @api sourceImage;
    @api QuickActionURL;
    @track _staticSourceImg;
    @track viewApplication = VIEW_APPLICATION_ACTION;
    @track submitCredit = SUBMIT_CREDIT_ACTION;
    @track viewPortfolio = VIEW_PORTFOLIO_ACTION;
    @track createQuote = CREATE_QUOTE_ACTION;

}