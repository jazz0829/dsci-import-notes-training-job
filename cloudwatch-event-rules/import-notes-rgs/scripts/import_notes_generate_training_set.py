"""
this code PostProcessing

Time needed: 32min on 15 slaves
"""

from pyspark import SparkContext
from pyspark.sql import SQLContext
from pyspark.sql.functions import col, collect_set, lit, udf, array, when
from pyspark.sql.types import *
from pyspark.sql.window import Window
from datetime import datetime, timedelta, date
import calendar
import os, boto3, json, argparse

# INITIALIZATION
sc = SparkContext()
spark = SQLContext(sparkContext=sc)

# PARSE PARAM
parser = argparse.ArgumentParser("EDA")
parser.add_argument("--input", '-i', metavar="file_input",
                    type=str, required=True,
                    help="input data location")
parser.add_argument("--output", '-o', metavar="file_output",
                    type=str, required=True,
                    help="output data location")
parser.add_argument("--log", '-l', metavar="log_output",
                    type=str, required=True,
                    help="output log location")
parser.add_argument("--mask", '-m', metavar="mask_month",
                    type=str, default="12",
                    help="number of months")
parser.add_argument("--start", '-s', metavar="start_date",
                    type=str, default=(date.today() - timedelta(days=date.today().weekday())- timedelta(days=365/12*13)).strftime("%Y-%m-%d"), # last Monday of this week
                    help="starting date")
parser.add_argument("--end", '-e', metavar="end_date",
                    type=str, default=(date.today() - timedelta(days=date.today().weekday())).strftime("%Y-%m-%d"),
                    help="ending date")
parser.add_argument("--user", '-u', metavar="username",
                    type=str, default="dsci-importnotes",
                    help="script runner")
conf = parser.parse_args()

PATH_IN     = conf.input
PATH_OUT    = conf.output
PATH_LOG    = conf.log
USERNAME    = conf.user
PROJECTNAME = 'ImportNotes'
TIMESTAMP   = datetime.now().strftime('%Y-%m-%d')

# this is the output location to publish the logs
PATH_PUBLISH = "s3://dsci-eol-data-bucket/prod/publish/"

log_statistics_list = []

def log_statistics(variable, value):
    log_statistics_list.append((TIMESTAMP, USERNAME, PROJECTNAME, variable, value))

def write_log():
    global log_statistics_list
    log_schema = StructType([
        StructField('Timestamp', StringType()),
        StructField('Username', StringType()),
        StructField('ProjectName', StringType()),
        StructField('Variable', StringType()),
        StructField('Value', StringType())
    ])

    if log_statistics_list:
        log_statistics_df = spark.createDataFrame(log_statistics_list, log_schema)
        log_statistics_df.repartition(1).write.mode('append').parquet(PATH_PUBLISH + 'ImportNotesETLSummary')
        log_statistics_list = []

# function to get the note type
def get_NoteType(AllocateMatchInfoJson, HasGLAccountSuggestions, HasGLAccountSuggestionsCommunity, syscreated):

    # if it has a Robotic Suggestion, then it's a target
    if HasGLAccountSuggestionsCommunity == True:
        return "Target"

    AllocationStatus = 'unknown'
    allocation = ''
    previousAllocation = ''
    match = ''

    if AllocateMatchInfoJson:
        x_dict = json.loads(AllocateMatchInfoJson)
        allocation = x_dict.get('allocation', {'source':''}).get('source','{}')
        previousAllocation = x_dict.get('previousAllocation', {'source':''}).get('source','{}')
        match = x_dict.get('match', {'source':''}).get('source','{}')

        condition_ManualAllocate = (((allocation == "8") | (allocation == 8) | (allocation == "{}")) & ((match == "{}") | (match == "")))
        condition_AutoAllocate = (~((allocation == "8") | (allocation == 8) | (allocation == "{}")) & ((match == "{}") | (match == "")))

        if condition_ManualAllocate:
            AllocationStatus = 'manual'
        if condition_AutoAllocate:
            AllocationStatus = 'automatic'

    condition_manualAllocatePreviousAllocate = (AllocationStatus == "manual") & (previousAllocation != '') & (previousAllocation != "8") & (previousAllocation != 8)
    if condition_manualAllocatePreviousAllocate:
        AllocationStatus = 'manual_previousAllocation'

    NoteType = "Unknown"
    if ((AllocationStatus == "manual") & (HasGLAccountSuggestions == False) & (syscreated > "2018-09-27")):
        NoteType = "Target"
    if ((~(AllocationStatus == "manual") | ~(HasGLAccountSuggestions == False)) & (syscreated > "2018-09-27")):
        NoteType = "NonTarget"
    return NoteType

get_NoteType_udf = udf(get_NoteType, StringType())

# there are some transactions that have a Null column instead of a False column. So, we turn null to false
def turn_null_to_false(InTransit):
    if InTransit:
        return(InTransit)
    return(False)

turn_null_to_false_udf = udf(turn_null_to_false, BooleanType())

# get the last day of previous month for each record
def get_mask_date(syscreated):
    last_date_of_previous_month = str(datetime.strptime(syscreated[:7] + "-01", '%Y-%m-%d') - timedelta(days=1))[:10]
    return (last_date_of_previous_month)

get_mask_date_udf = udf(get_mask_date, StringType())

def run_etl():
    # LOAD DATA
    import_notes_combined = spark.read.parquet(PATH_IN + "ImportNotes/*/*/*.parquet")

    # TRANSFORMATION
    import_notes_combined = import_notes_combined.withColumnRenamed("InTransit", "InTransit_old")
    import_notes_combined = import_notes_combined.withColumn("InTransit",turn_null_to_false_udf(import_notes_combined.InTransit_old))

    #Correcting the NoteType 
    import_notes_combined = import_notes_combined.withColumn("NoteType",get_NoteType_udf(import_notes_combined.AllocateMatchInfoJson, import_notes_combined.HasGLAccountSuggestions, import_notes_combined.HasGLAccountSuggestionsCommunity, import_notes_combined.syscreated))

    import_notes_eda = import_notes_combined.select(['ID', 'Division', 'AmountFC', 'ImportNote', 'AccountBankAccount', 'syscreated', 'EntryDate', 'GLAccountID', 'RGSCode', 'ExactRGSCode', 'ExactRGSCode_sysmodified', 'InTransit', 'NoteType'])
    import_notes_eda = import_notes_eda.withColumn("syscreated_year", import_notes_eda.syscreated.substr(1,4)).withColumn("syscreated_month", import_notes_eda.syscreated.substr(6,2))

    # CREATING THE EDA SET
    import_notes_eda.write.mode("overwrite").partitionBy("InTransit", "syscreated_year", "syscreated_month").parquet(PATH_OUT + 'ImportNotesEDA')

    import_notes_eda = spark.read.parquet(PATH_OUT + 'ImportNotesEDA/InTransit=false/*/*/*.parquet')

    # CREATING THE TRAININGSET
    available_dates = import_notes_eda.groupby(import_notes_eda.syscreated.substr(1,7)).count().sort(col("substring(syscreated, 1, 7)")).collect()
    year_month_list = [{"year": x[0][:4], "month":x[0][5:7]} for x in available_dates]

    import_notes_training = import_notes_eda.filter('ExactRGSCode IS NOT NULL AND ExactRGSCode_sysmodified > "2019"')
    import_notes_training = import_notes_training.filter('ExactRGSCode != "BLimKruSto"')

    for ym in year_month_list:
        m_str = ym["month"]
        y_str = ym["year"]
        print(m_str,y_str)
        end_of_this_month = str(datetime(int(y_str), int(m_str), calendar.monthrange(int(y_str),int(m_str))[-1]))[:10]
        first_of_next_month = str(datetime(int(y_str), int(m_str), calendar.monthrange(int(y_str),int(m_str))[-1])+timedelta(days=1))[:10]
        temp_date = datetime(int(y_str), int(m_str), 1)-timedelta(int(conf.mask) * 30)
        end_of_limit_month = str(datetime(temp_date.year, temp_date.month, calendar.monthrange(int(temp_date.year), int(temp_date.month))[-1]))[:10]

        # Create the mask of last year
        import_notes_training_of_interest = import_notes_training.filter('syscreated >= "%s" AND syscreated < "%s"'%(end_of_limit_month, first_of_next_month))

        mask_of_accum_period = import_notes_training_of_interest.select(["Division", "ExactRGSCode"]).distinct()
        mask_of_accum_period = mask_of_accum_period.groupby("Division").agg(collect_set("ExactRGSCode").alias("ActiveRGS")) # pylint: disable=not-callable
        mask_of_accum_period = mask_of_accum_period.withColumn("year_month",lit(end_of_this_month))
        mask_of_accum_period.repartition(1).write.mode("overwrite").parquet(os.path.join(PATH_OUT, 'Temporal_Mask/%s-%s' % (y_str, m_str)))


    ## now load all the mask that are created
    mask_aggregated = spark.read.parquet(os.path.join(PATH_OUT, 'Temporal_Mask/*/*.parquet'))

    # change some column names
    mask_aggregated = mask_aggregated.withColumnRenamed("Division", "Division_mask")
    import_notes_training = import_notes_training.withColumn("date_mask", get_mask_date_udf(import_notes_training.syscreated))

    # join import notes with mask
    import_notes_training_with_mask = import_notes_training.join(mask_aggregated, (mask_aggregated.year_month == import_notes_training.date_mask) & (mask_aggregated.Division_mask == import_notes_training.Division), 'left')

    # take care of the empty masks
    import_notes_training_with_mask = import_notes_training_with_mask.withColumnRenamed("ActiveRGS","ActiveRGS_badformat")
    null_value = array([])
    null_value = null_value.cast('array<string>')
    import_notes_training_with_mask = import_notes_training_with_mask.withColumn("ActiveRGS", when(import_notes_training_with_mask.ActiveRGS_badformat.isNull(),null_value).otherwise(import_notes_training_with_mask.ActiveRGS_badformat))
    import_notes_training_with_mask = import_notes_training_with_mask.withColumn("ActiveRGS", import_notes_training_with_mask.ActiveRGS.cast("string"))

    # add a partitioning column
    import_notes_training_with_mask = import_notes_training_with_mask.withColumn("year_month", import_notes_training_with_mask.syscreated.substr(1,7))

    import_notes_training_with_mask = import_notes_training_with_mask.select([
        'ID', 'Division', 'ImportNote', 'AmountFC', 'ActiveRGS',
        'ExactRGSCode', 'syscreated', 'EntryDate', 'NoteType', 'year_month'])
    import_notes_training_with_mask = import_notes_training_with_mask.filter((col('syscreated') >= lit(conf.start)) & (col('syscreated') < lit(conf.end)))

    # write results
    import_notes_training_with_mask.repartition(5).write.mode("overwrite").partitionBy("year_month").parquet(os.path.join(PATH_OUT, 'ImportNotesTraining'))

def collect_statistics():
    # load data
    training_set_new = spark.read.parquet(os.path.join(PATH_OUT, 'ImportNotesTraining/*/*.parquet'))

    # EDA STARTS
    # Number of records and the increase of size
    log_statistics("Size of training set", training_set_new.count())

    # number of records per month
    results = training_set_new.groupBy(training_set_new.syscreated.substr(1,7)).count().sort(col("substring(syscreated, 1, 7)").desc()).collect()
    for r in results:
        log_statistics("Number of records in training set for " + r[0], r[1])

    # Division Sets
    log_statistics("Number of unique divisions", training_set_new.select("Division").distinct().count())

    # Other statsitics
    log_statistics("Number of unique ExactRGSCodes", training_set_new.select("ExactRGSCode").distinct().count())
    log_statistics("Starting date of data", training_set_new.agg({"syscreated": "min"}).collect()[0][0][-23:-13])
    log_statistics("End date of data", training_set_new.agg({"syscreated": "max"}).collect()[0][0][-23:-13])

    #TODO: give some statistics about target data

    # Store the results
    write_log()


if __name__ == "__main__":
    # this function creates the training data and a few other useful datasets
    run_etl()

    # the following function writes the EMR statistics. however, it fails in Dev environment
    try:
        collect_statistics()
    except Exception as e:
        print("ERROR occured during collection of statistics")
        print(e)

