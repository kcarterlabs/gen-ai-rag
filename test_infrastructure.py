"""
Test newly refactored modular infrastructure
"""

def test_infrastructure_structure():
    """Verify module structure is correct"""
    import os
    
    base_path = "/home/kenny/rag-genai/infra"
    
    # Check main files
    main_files = ["main.tf", "ouputs.tf", "config.yaml"]
    for file in main_files:
        path = os.path.join(base_path, file)
        assert os.path.exists(path), f"Missing {file}"
        print(f"✓ Found {file}")
    
    # Check modules directory
    modules_path = os.path.join(base_path, "modules")
    assert os.path.exists(modules_path), "Missing modules directory"
    print(f"✓ Found modules directory")
    
    # Check each module
    modules = ["lambda", "api_gateway", "policies"]
    required_files = ["main.tf", "variables.tf", "outputs.tf"]
    
    for module in modules:
        module_path = os.path.join(modules_path, module)
        assert os.path.exists(module_path), f"Missing {module} module"
        print(f"✓ Found {module} module")
        
        for file in required_files:
            file_path = os.path.join(module_path, file)
            assert os.path.exists(file_path), f"Missing {file} in {module}"
            print(f"  ✓ {module}/{file}")
    
    print("\n✅ All infrastructure modules properly structured!")


def test_module_content():
    """Verify modules contain expected resources"""
    import re
    
    base_path = "/home/kenny/rag-genai/infra"
    
    # Test Lambda module
    lambda_main = os.path.join(base_path, "modules/lambda/main.tf")
    with open(lambda_main, 'r') as f:
        content = f.read()
        assert 'aws_lambda_function' in content, "Lambda module missing lambda functions"
        assert 'chat' in content, "Lambda module missing chat function"
        assert 'ingest' in content, "Lambda module missing ingest function"
        assert 'aws_s3_bucket_notification' in content, "Lambda module missing S3 trigger"
        print("✓ Lambda module has all required resources")
    
    # Test API Gateway module
    api_main = os.path.join(base_path, "modules/api_gateway/main.tf")
    with open(api_main, 'r') as f:
        content = f.read()
        assert 'aws_apigatewayv2_api' in content, "API Gateway module missing API"
        assert 'aws_apigatewayv2_integration' in content, "API Gateway module missing integration"
        assert 'aws_apigatewayv2_route' in content, "API Gateway module missing routes"
        assert 'POST /chat' in content, "API Gateway module missing chat route"
        print("✓ API Gateway module has all required resources")
    
    # Test Policies module
    policies_main = os.path.join(base_path, "modules/policies/main.tf")
    with open(policies_main, 'r') as f:
        content = f.read()
        assert 'bedrock' in content.lower(), "Policies module missing Bedrock policy"
        assert 's3' in content.lower(), "Policies module missing S3 policy"
        assert 'dynamodb' in content.lower(), "Policies module missing DynamoDB policy"
        print("✓ Policies module has all required resources")
    
    # Test main.tf uses modules
    main_tf = os.path.join(base_path, "main.tf")
    with open(main_tf, 'r') as f:
        content = f.read()
        assert 'module "policies"' in content, "main.tf not using policies module"
        assert 'module "lambda"' in content, "main.tf not using lambda module"
        assert 'module "api_gateway"' in content, "main.tf not using api_gateway module"
        # Verify no direct Lambda or API Gateway resources in main
        assert 'resource "aws_lambda_function"' not in content, "main.tf should not have direct lambda resources"
        assert 'resource "aws_apigatewayv2_api"' not in content, "main.tf should not have direct API Gateway resources"
        print("✓ main.tf properly uses modules")
    
    print("\n✅ All modules contain expected resources!")


if __name__ == "__main__":
    import os
    print("=" * 60)
    print("Testing Modular Infrastructure")
    print("=" * 60)
    print()
    
    try:
        test_infrastructure_structure()
        print()
        test_module_content()
        print()
        print("=" * 60)
        print("✅ ALL TESTS PASSED - Infrastructure is properly modularized!")
        print("=" * 60)
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
    except Exception as e:
        print(f"\n❌ Error: {e}")
