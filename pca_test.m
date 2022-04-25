%% load
test_dir = "nsynth-test\audio";
valid_dir = "nsynth-valid\audio";

[test_audio,test_files] = loadWavs(test_dir);
[valid_audio,valid_files] = loadWavs(valid_dir);
%% pca for training data
n_pca = 100;
coeffs = pca(valid_audio,"NumComponents",n_pca);
%% Train model with projected training set
inst_labels = ["bass","brass","flute","guitar","keyboard","mallet","organ","reed","string","synth_lead","vocal"];

%% Make datasets for training
X_train = (valid_audio-mean(valid_audio,2))*coeffs;
Y_train = zeros(length(valid_files),1);
for i = 1:length(inst_labels)
    Y_train(find(contains(valid_files,inst_labels(i)))) = i;
end

%% Make datasets for eval
X_test = (test_audio-mean(test_audio,2))*coeffs;
Y_test = zeros(length(test_files),1);
for i = 1:length(inst_labels)
    Y_test(find(contains(test_files,inst_labels(i)))) = i;
end

%% Evaluate model
Cvals = [1e-3, 2e-3, 5e-3, 1e-2, 1e-1, 1, 1e2, 1e3];

[model,model_error] = evalSVN("gaussian",Cvals(end),X_train,Y_train,X_test,Y_test,true);

function [mdl, error_rate] = evalSVN(kernel,Cval,X_train,Y_train,X_test,Y_test,showConf)

    t = templateSVM('BoxConstraint',Cval,'KernelFunction',kernel,'KernelScale','auto');
    mdl = fitcecoc(X_train,Y_train,'Learners',t,'Coding','onevsone');
    test_results = predict(mdl,X_test);
    if showConf
        figure;
        confusionchart(Y_test,test_results,'RowSummary','row-normalized')
    end
    error_rate = sum(Y_test~=test_results)/length(Y_test);

end

function [wavs, files] = loadWavs(directory)

    files = string(ls(directory+"\*.wav"));
    wavs = [];
    for i = 1:length(files)
        wavs(i,:) = audioread(directory+"\"+files(i));
    end

end