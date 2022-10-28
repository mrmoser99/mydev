/**
 * Scheduler class to schedule UpdateQuoteStatusBatch job. 
 * @author: Anujit
 * date created: 01-10-2021
 */
public with sharing class UpdateQuoteStatusScheduler implements Schedulable {

    public static final String SCHEDULED_TIME = '0 0 0 1/1 * ? *';
    public static final String CLASS_NAME = 'UpdateQuoteStatusScheduler';

    private Integer batchSize;

    public UpdateQuoteStatusScheduler(Integer batchSize){
        this.batchSize = batchSize;
    }

    public static Id scheduleBatch(Integer chunkSize) {
        return System.schedule(CLASS_NAME, SCHEDULED_TIME, new UpdateQuoteStatusScheduler(chunkSize));
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateQuoteStatusBatch(), batchSize);
    }
}