/**
 * Reduce one or more LDS errors into a string[] of error messages.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
const reduceErrors = errors => {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
            // Remove null/undefined items
            .filter((error) => !!error)
            // Extract an error message
            .map((error) => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter((message) => !!message)
    );
}

/** Create and dispatche event to show notification 
 * @param context - context for Event Target
 * @param message - message text
 * @param variant - variant of the notification, may be 'info', 'error' or 'success' 
*/
const dispatchPopUpNotification = (context, message, variant) => {
    const showError = new CustomEvent('shownotification', { 
        detail: {
            message: message, 
            variant: variant
        }
    });
    context.dispatchEvent(showError);
}

/** Show notification in the top of the page. The option 'variant' may be 'info', 'error' or 'success' 
 * @param context - context for component search
 * @param message - message text
 * @param variant - variant of the notification, may be 'info', 'error' or 'success' 
*/
const showPopUpNotification = (context, message, variant) => {
    // call public method from child
    context.template.querySelector('c-pop-up-notification-cmp').showNotification(message, variant);
}

/** Return param value from URL by parame nema
 * @param url - URL
 * @param key - param key (name)
 * @return String param value 
*/
const getUrlParamValue = (url, key) => {
    return new URL(url).searchParams.get(key);
}

/** The component that imports the function uses the exported names */
export { reduceErrors, showPopUpNotification, dispatchPopUpNotification, getUrlParamValue};
export { constants,esignStatuses,quoteStatuses,smartcommDocType,itadLevels, screenNamesEN, screenNamesTR,frequency,frequencyTranslated,
    interestTranslated,insuranceDispTranslated, smartcommDocTypeEN, disableFieldStages, offerRVType } from './constants';