require 'tacoma'
require 'pry'

describe "Tacoma::Tool" do

  let(:tacoma_config) {
    YAML.load_file("spec/fixtures/.tacoma.yml")
  }

  it "default values" do
    expect(Tacoma::Tool::DEFAULT_AWS_REGION).to eq("eu-west-1")
  end

  it "#config" do
    allow(Tacoma::Tool).to receive(:config) { tacoma_config }
    expect(Tacoma::Tool.config).to eq(tacoma_config)
  end

  it "#load_vars" do
    allow(Tacoma::Tool).to receive(:config) { tacoma_config }
    Tacoma::Tool.load_vars("another_project")
    expect(Tacoma::Tool.aws_identity_file).to eq("/path/to/another_pem.pem")
    expect(Tacoma::Tool.aws_secret_access_key).to eq("ANOTHERECRETACCESSKEY")
    expect(Tacoma::Tool.aws_access_key_id).to eq("ANOTHERACCESSKEYID")
    expect(Tacoma::Tool.region).to eq(Tacoma::Tool::DEFAULT_AWS_REGION)
    expect(Tacoma::Tool.repo).to eq("$HOME/projects/another_project")
    expect(Tacoma::Tool.s3cfg).to eq({"gpg_passphrase" => "my_gpg_passphrase" })
  end

  it "#load_vars validate_vars fail" do
    allow(Tacoma::Tool).to receive(:config) { tacoma_config }
    expect(STDOUT).to receive(:puts).with("Cannot find @aws_secret_access_key key, check your YAML config file.\nCannot find @aws_access_key_id key, check your YAML config file.")
    subject = Tacoma::Tool.load_vars("error_project")
    expect(subject).to eq(false)
  end

  it "#build_template_path build a absolute path" do
    allow(Tacoma::Tool).to receive(:config) { tacoma_config }
    tacoma_command = Tacoma::Command.new
    subject = tacoma_command.build_template_path("s3cfg")
    expect(subject).to_not match(/\.\./)
    expect(subject).to match(/template\/s3cfg/)
  end

  it "#switch to another_project render tools templates" do
    tacoma_command = Tacoma::Command.new
    allow(Tacoma::Tool).to receive(:config) { tacoma_config }
    expect(tacoma_command).to receive(:template).at_least(5).times

    response = tacoma_command.switch("another_project")

    expect(tacoma_command.instance_variable_get("@aws_identity_file")).to be_a(String)
    expect(tacoma_command.instance_variable_get("@aws_secret_access_key")).to be_a(String)
    expect(tacoma_command.instance_variable_get("@aws_access_key_id")).to be_a(String)
    expect(tacoma_command.instance_variable_get("@region")).to be_a(String)
    expect(tacoma_command.instance_variable_get("@repo")).to be_a(String)
    expect(tacoma_command.instance_variable_get("@s3cfg")).to be_a(Hash)

    expect(response).to eq(true)
  end

end
