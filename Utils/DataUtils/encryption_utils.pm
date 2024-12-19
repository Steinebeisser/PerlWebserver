package encryption_utils;

use Crypt::CBC;
use Crypt::Rijndael;
use MIME::Base64;

my $cipher;
my $longKey = no_upload::get_cookie_encryption_key();
my $longIV = no_upload::get_cookie_encryption_key();
setup_cipher($longKey, $longIV);

sub encrypt_data {
    my ($plaintext) = @_;
    # print ("encrypt_with_public\n");
    # print ("long key $longKey\n");

    my $padded_text = add_padding($plaintext);

    $crypted = $cipher->encrypt($padded_text);

    my $encoded_text = encode_base64($crypted);
    # return $crypted
    return $encoded_text;
}


sub decrypt_data {
    my ($crypted) = @_;
    # print ("decrypt_with_public\n");
    # print ("long key $longKey\n");

    my $crypted_text = decode_base64($crypted);

    my $decrypted = $cipher->decrypt($crypted_text);
    # print("decrypted $decrypted\n");

    my $unpadded_text = remove_padding($decrypted);
    # print("unpadded_text $unpadded_text\n");
    return $unpadded_text;
}

sub setup_cipher {
    my ($key, $iv) = @_;
    chomp($key);
    chomp($iv);
   
    # my $longKey =  hash_utils::calculate_16_byte_hash($key);

    # my $longIV = hash_utils::calculate_16_byte_hash($iv);

    my $longKey = "bc71d8a53328c7d2";
    my $longIV = "4979967588533338";


    print("long key_ $longKey\n");
    print ("long iv_ $longIV\n");
    $cipher = Crypt::Rijndael->new($longKey, Crypt::Rijndael::MODE_CBC());
    $cipher->set_iv($longIV);
}

sub add_padding {
    my ($plaintext) = @_;
    my $block_size = 16;
    my $padding_length = $block_size - (length($plaintext) % $block_size);
    return $plaintext . chr($padding_length) x $padding_length;
}

sub remove_padding {
    my ($ciphertext) = @_;
    my $padding_length = ord(substr($ciphertext, -1));
    return substr($ciphertext, 0, -$padding_length);  
}
1;