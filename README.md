# Transformational Machine Learning

Introduction

Here, We explore a new learning methodology called Transformational Learning (TML). This is very effective for modeling a task from a group of related tasks with related datasets. Transformational
learning transforms local intrinsic features of a dataset which has to be modeled into extrinsic features which can be used to model with more efficiency by using the machine learning models learned on
related problem datasets. Intuitively when we use the models learned on related problems, they contain extra information learned from the related datasets, so when we apply those models to the
new problem dataset they have the learned information and new information from the task dataset which when trained results in reduction in modeling leading to a better efficient model than the
conventional baseline Machine learning model. This project intends to use this TML on QSAR; a very important step in the pharmacological industry to show that TML is very effective for these related
tasks like protein synthesis, species targeting, and functional structure evaluation.
Machine Learning refers to the idea of machine models finding patterns from examples and generalizing them to new training samples. So, when we have multiple related problems in machine learning,
What happens if these problems are correlated? Would that be any special case? Does one task with a Machine learning model encode important information useful for the other problem? If so, how can 
we use this information? This paradox can be solved by Transformational learning (TML). Transformational Learning is similar to the human thought process while processing knowledge. Our brain tries to process freshly received knowledge by encoding it in terms of knowledge that we have previously acquired (Formally forming relations). So, if the new knowledge is dependent on old knowl-
edge, it becomes an extension of it. In the same way, we have problems with associated knowledge of the tasks which we solve and store the information from them as experience. This is exactly the
process in TML where we use models of related tasks to produce transformed features on our task and model the task with transformed features.
Transformational Learning is generally synergistic to MTL (Multi-Task Learning), TL (Transfer Learning) and Stacking

Problem Formulation

 QSAR is the issue that needs to be solved. In the pharmacological industry, Early-phase drug discovery frequently involves evaluating a drug’s functional structure(generally involves discovery), in-
teractions with target proteins, and potential therapeutic effects on target species. This procedure is known as QSAR. For Quantitative Structure-Activity Relationships (QSAR) predictions, a target is often a protein
or genome, and a list of chemical substances (small molecules or structures) with related activities is also typically provided (Ex: Activation or inhibition of the target protein). A predictive model is then
learned from features of the protein (E.g: functional features, structural features) to the target. 

Methodology

The methodology we used here is Bayesian inference, in which we use dependencies between our models that we could not use if they were to be used independently or in a baseline ML model. By exploiting
the correlation between these models, we can use data much more efficiently because we are taking the knowledge of models learned previously on related data into account to make our prediction. This
is done through Bayes Inference. In this case, we are essentially using the dependencies of all other datasets on our dataset to maximize our probability of error reduction, thereby increasing modeling efficiency. Transformational learning
transforms intrinsic features into extrinsic features by using machine learning models learned on related problem sets. Intuitively, when we use models learned on related problems, they contain information
learned from related datasets, so when we apply those models to the new problem dataset, they have the information learned as well as new information from the dataset, so the error is further reduced,
leading to a more efficient model. Because of this property, we do not have to formulate models when a new model or dataset arrives; instead, we can incrementally add them to our transformational learning
model thereby creating an ecosystem of sorts. This ecosystem can be further expanded with stacking and used to model datasets.
We employed five machine learning algorithms that are deemed very popular and their implementations, easily accessible from R: random forest (RF, as implemented in the range R package), support vector machine (SVM, ksvm R package), k-nearest neighbor (KNN, FNN R package), neural networks
(NN, tensorflow.keras python package), and extreme gradient boosted trees (XGB, XGBoost R pack-
age).
Hyperparameters were selected as follows: in all RF experiments, we used 500 trees, a third of the total number of variables were considered at each split, and five observations were used in each terminal
node. For the experiments with SVMs, we used RBF kernels with a gamma value of 0.65 and a cost of 1.0. The chosen RF and SVM hyperparameter sets were the ones that produced the best overall
performance after having been tested on a smaller subset of datasets randomly selected. For KNN, the number of neighbors (‘k’) was chosen individually for each QSAR model using 3-fold cross-validation.
For NNs, we tested on a small subset of the datasets several fully connected feedforward architectures. In addition, we used dropping-out and L2 norm-penalization at different rates to minimize the
risk of overfitting. We chose for the baseline experiments an architecture that consisted of 1 hiddenlayer with 128 neurons and 1 output neuron. ReLU activation functions were used in the hidden layer.
For the TML experiments, the NN architecture consisted of 2 hidden layers, the first one with 712 neurons and the second one, with 128, and both with ReLUs. We used ADAM as the optimizer in
both sets of experiments. For the baseline and TML experiments, XGB’s hyperparameters for each dataset models were chosen by exploring the following grid: number of rounds values 1000 and 1500,learning rate values in 0.001,
0.01, 0.1, 0.2, and 0.3. The hyperparameter set producing the best model performance was chosen using an inner validation split of 30. The model has to learn a predictive mapping from molecular
representation to activity: So first Baseline ML methods (Random Forest, KNN, DNN, XGB, SVM) are first applied to each QSAR prediction task, yielding prediction models for activities which are then
used for the generation of the extrinsic features by using these models by applying them to the new task training data. In the TML approach, for a new QSAR task, we apply an ML method to produce a model (which
could be different from any of the previously used but here we are using all of them again for the ecosystem to be generated) to make a new prediction by using all the previously trained models. The
attributes that are now extrinsic thanks to them being the predictions from baseline QSAR model on the training set. So, models that are trained on the target proteins are used on the dataset for
which the target variable is activities on species (E.g. Homosapiens etc.). We are implementing our transformational learning methods on protein synthesis for activities (inhibition activation 0 or 1) on
species for reducing its mean square error and precision error.

Results

As we can see in the table.1 just by applying our traditional approach, we got an accuracy of 90.84 percent and a precision error of 9.15 percent. We can observe the Root Mean Square Error as 0.75.
On the same dataset, when we use the Transformational Machine Learning approach, the accuracy has increased to 91.41 percent, and the precision has been reduced to 8.58 percent, with the Root Mean
Square Error valued at 0.69 
Extending forward, using the Baseline and TML model combined, the accuract has further extended to 91.67 with a slight improvment, with the RMSE value being least to 0.66425.
Finally, using the MTL and Base model combined, the RMSE value being goes to 0.67381.
The preliminary results indicate not much increase in efficiency but still an increase in efficiency. This shows improvement because of partial models and example information as we are giving both
significant value but here we need to give task dataset more importance so we will stack dataset example features with transformed features.

Conclusion

This shows the prominence of transformed features as their efficiency is compared to baseline Machine
learning. Thereby proving this, we can guarantee an incremental increase in efficiency by stacking the
examples with the transformed features which will be proven further into the project. We also intend
to explore the cascading of different techniques like MTL and stacking with TML to check for the
formulation of a further efficient model. Drug targeting, Meta Machine Learning model prediction,
and drug similarity were the only topics covered in the transformational machine learning research
paper we focused on. Also, we are planning to use the dataset to test scale change and explore the
possibilities of the ecosystem to further the scope of its applications in day-to-day life
