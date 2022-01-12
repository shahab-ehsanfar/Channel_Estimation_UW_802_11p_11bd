function [ y_out ] = do_emulate_cp(config,h_hat,y,blk,mode,xd)
% This function emulates the CP at the receiver side
% In other words, the channel h_hat looks circulant to the signal of interest
%
% TU Dresden
% Shahab

nT = config.nT;
nR = config.nR;

N_uw = config.UW_length;
N = config.N;


if strcmp(mode,'for_data')
    %% CP Emulation for data 
    
    numPaths = config.numPaths; 
    xp_iT = config.preamble.xp_iT;    
    
    % Copy the UW part and add it to the beginning of the block
    y_d0 = zeros(N,nR);
    for iR = 1:nR
        y_d0(:,iR) = y(1:N,iR,blk) + padarray(y(N+1:N+numPaths,iR,blk),N-numPaths,'post');
    end
    
    % Calculate the signal from the known terms
    xp_interf = zeros(N_uw,nR);
    for iR = 1:nR
        for iT = 1:nT
            xp_interf(:,iR) = xp_interf(:,iR) + ifft_u(fft_u(xp_iT(N_uw+1:end,iT)).*fft(h_hat(:,iT,iR),N_uw));
        end
    end
    
    % Remove the uw-interference and extract the circulant-channeled data signal
    yd = zeros(N,nR);
    for iR = 1:nR
        yd(:,iR) = y_d0(:,iR) - padarray(xp_interf(1:numPaths,iR),N - numPaths,'post');
    end    
    y_out = yd;
    
elseif strcmp(mode,'for_data_cpUW')
    %% CP Emulation for data 
    xp_iT = config.UW_inTime_withcp;
    numPaths = config.numPaths; 
    Ncp = config.Ncp;
    
    % Copy the UW part and add it to the beginning of the block
    y_d0 = zeros(N,nR);
    for iR = 1:nR
        y_d0(:,iR) = y(1:N,iR,blk) + padarray(y(N+1:N+numPaths,iR,blk),N-numPaths,'post');
    end
    
    % Calculate the signal from the known terms
    xp_interf = zeros(numPaths,nR);
    for iR = 1:nR
        for iT = 1:nT
            filtered_xp = conv(h_hat(:,iT,iR),xp_iT(:,iT));
            xp_interf(:,iR) = xp_interf(:,iR) + filtered_xp(1:numPaths) + [filtered_xp(end-numPaths+2:end); 0];
        end
    end
    
    % Remove the uw-interference and extract the circulant-channeled data signal
    yd = zeros(N,nR);
    for iR = 1:nR
        yd(:,iR) = y_d0(:,iR) - padarray(xp_interf(1:numPaths,iR),N - numPaths,'post');
    end    
    y_out = yd;

elseif strcmp(mode,'for_uw')
    %% CP Emulation for the Unique Word (Pilots) part

    numPaths = config.numPaths;
    
    % Copy the beginning of data part and add it to the beginning of the UW part
    y_uw0 = zeros(N_uw,nR);
    for iR = 1:nR
        y_uw0(:,iR) = y(1:N_uw,iR,blk) + y(N+1:end,iR,blk); 
    end    
       
    % Calculate the ISI leakage from data to UW part
    x_leakage = zeros(numPaths-1+N_uw,nT);
    x_padded = zeros(2*(numPaths-1)+N_uw,nT);
    for iT = 1:nT
        x_leakage(:,iT) = [xd(end-numPaths+2:end,iT); xd(1:N_uw,iT)];
        x_padded(:,iT) = padarray(x_leakage(:,iT),numPaths-1,'pre');    
    end
    x_filtered = zeros(2*(numPaths-1)+N_uw,nR);
    interference = zeros(N_uw,nR);
    for iR = 1:nR
       for iT = 1:nT
           x_filtered(:,iR) = x_filtered(:,iR) + filter(h_hat(:,iT,iR),1,x_padded(:,iT));              
       end
       interference(:,iR) = x_filtered(end-N_uw+1:end,iR);
    end   
        
    % Remove the interference and extract the circulant-channeled UW signal
    y_uw = zeros(N_uw,nR);
    for iR = 1:nR
       y_uw(:,iR) = y_uw0(:,iR) - interference(:,iR);
    end    
    y_out = y_uw;
        
    
end





end

