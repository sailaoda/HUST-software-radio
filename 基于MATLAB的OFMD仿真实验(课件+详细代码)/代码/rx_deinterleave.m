

function out_bits = rx_deinterleave(in_bits, fftlen, modulate_level)

interleaver_depth = fftlen * modulate_level;
num_symbols = length(in_bits)/interleaver_depth;
distance = interleaver_depth/2;
%distance = 16;

s = max([interleaver_depth/fftlen/2 1]);

perm_patt = s*floor((0:interleaver_depth-1)/s)+ ...
   mod((0:interleaver_depth-1)+floor(distance*(0:interleaver_depth-1)/interleaver_depth),s);

deintlvr_patt = distance*perm_patt - (interleaver_depth-1)*floor(distance*perm_patt/interleaver_depth);
single_deintlvr_patt = deintlvr_patt + 1;

deintlvr_patt = interleaver_depth*ones(interleaver_depth, num_symbols);
deintlvr_patt = deintlvr_patt*diag(0:num_symbols-1);
deintlvr_patt = deintlvr_patt+repmat(single_deintlvr_patt', 1, num_symbols);
deintlvr_patt = deintlvr_patt(:);

out_bits(deintlvr_patt) = in_bits;

