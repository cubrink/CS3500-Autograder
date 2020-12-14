#!/bin/bash

# Filename    :   brinkerc.sh

# Project     :   CS3500 HW8
# Description :   Prolog autograder
# Author      :   Curtis Brinker
# Date        :   2020-12-13


########################################
#                                      #
#                 Setup                # 
#                                      #
########################################

# Ensure fresh workspace, delete then recreate
rm -rf ./submissions/
rm -rf ./expected_output/
rm -rf ./sample_input/
rm -rf ./student_outputs/
rm -f ./grades.txt

mkdir -p ./submissions/
mkdir -p ./expected_output/
mkdir -p ./sample_input/
mkdir -p ./student_outputs/

# Unzip into appropriate folders
unzip -qo ./submissions.zip -d ./submissions/
unzip -qo ./expectedOutput.zip -d ./expected_output/
unzip -qo ./sampleInput.zip -d ./sample_input/

# Ensures that all provided files are converted to unix line endings
find ./sample_input/ -type f -print0 | xargs -0 dos2unix --
find ./expected_output/ -type f -print0 | xargs -0 dos2unix --
find ./submissions/ -type f -print0 | xargs -0 dos2unix --



########################################
#                                      #
#                Testing               # 
#                                      #
########################################

# Calculate total amount of files that will be graded
total_files=$(ls ./expected_output/*.out | wc -w) 

# Perform test on each submission
for submission in $(ls ./submissions/*.pl); do
    # Get user id and create dir for the user
    user="$(basename "$submission" .pl)"
    mkdir -p ./student_outputs/"$user"/

    same_files=0
    total_files=$(ls ./expected_output/*.out | wc -l)

    suspicion=0     # Flag to mark if we suspect student is hard-coding solutions

    # Run input files
    for input_file in ./sample_input/*.txt; do
        # Run input file for each program
        input_name="""$(basename "$input_file")"""
        swipl "$submission" $(cat "$input_file") > ./student_outputs/"$user"/"$input_name".out
    done

    # Compare outputs
    for output_file in ./expected_output/*.out; do
        # Check if files match expected output
        output_name="""$(basename "$output_file")"""
        diff_lines=$(diff ./student_outputs/$user/"$output_name" \
                          ./expected_output/"$output_name" \
                          --ignore-space-change \
                          --ignore-case \
                          --ignore-blank-lines | egrep -c "^<|^>")
        if (( diff_lines == 0 )); then
            same_files=$((same_files+1))
        fi

        # Flag if solution is written into the submission
        if [[ $(cat "$submission" | grep -Fc "$(cat "$output_file")") > 0 ]]; then
            suspicion=1
        fi
    done

    # Calculate score
    score="$(((same_files*100)/(total_files)))"
    echo -n "$user, $score" >> grades.txt
    if [[ $suspicion > 0 ]]; then 
        # Mark grade as suspicious if we had seen potentially hard-coded answers 
        echo -n "*" >> grades.txt
    fi
    echo >> grades.txt
done



########################################
#                                      #
#               Tear-down              # 
#                                      #
########################################

# Remove folders when done
rm -rf ./submissions
rm -rf ./expected_output/
rm -rf ./sample_input/
rm -rf ./student_outputs/
